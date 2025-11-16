"""
Azure Text Analytics PII Detection

Uses Azure Cognitive Services Text Analytics API for AI-powered PII detection.
Detection happens in Azure cloud, redaction happens locally.

Best Practices Implemented:
- ✅ Native async: Uses azure.ai.textanalytics.aio (Azure's official async client)
- ✅ Connection pooling: Azure SDK handles connection reuse automatically
- ✅ Retry logic: Built into Azure SDK
- ✅ Secure Authentication: Uses Azure AD (client_id, client_secret, tenant_id) instead of API keys
- ✅ Fallback: ThreadPoolExecutor (last resort)
"""

from typing import List, Dict, Any
from ..base import RedactionResult, RedactionToken, RedactionType
import hashlib
import asyncio


class AzureTextAnalyticsPIIDetector:
    """
    Azure Text Analytics AI-powered PII detector.

    Flow:
    1. Send text to Azure Text Analytics API (cloud detection)
    2. Receive PII entities with positions and confidence scores
    3. Redact locally based on Azure's AI detection results

    Azure Setup Required:
    1. Create App Registration in Azure AD
    2. Grant permissions to Cognitive Services
    3. Create Azure Cognitive Services resource
    4. Add to .env:
       AZURE_CLIENT_ID=your_client_id
       AZURE_CLIENT_SECRET=your_client_secret
       AZURE_TENANT_ID=your_tenant_id
       AZURE_TEXT_ANALYTICS_ENDPOINT=https://your-resource.cognitiveservices.azure.com/
    """

    def __init__(self, endpoint: str, credential: Any = None, language: str = 'en'):
        """
        Initialize Azure Text Analytics PII detector.

        Args:
            endpoint: Azure Text Analytics endpoint URL
            credential: Azure credential (ClientSecretCredential or DefaultAzureCredential)
            language: Language code (default: 'en')
        """
        self.endpoint = endpoint.rstrip('/')
        self.credential = credential
        self.language = language
        self._client = None

    def _get_client(self):
        """Lazy initialization of Azure sync client using Azure AD authentication."""
        if self._client is None:
            try:
                from azure.ai.textanalytics import TextAnalyticsClient

                if not self.credential:
                    raise ValueError(
                        "Azure credential is required. Initialize AzureProvider with "
                        "client_id, client_secret, and tenant_id."
                    )

                self._client = TextAnalyticsClient(
                    endpoint=self.endpoint,
                    credential=self.credential
                )
            except ImportError:
                raise ImportError(
                    "Azure Text Analytics SDK not installed. "
                    "Install with: pip install azure-ai-textanalytics azure-identity"
                )
        return self._client

    def _get_async_client(self):
        """Get Azure async client using Azure AD authentication (native async)."""
        try:
            from azure.ai.textanalytics.aio import TextAnalyticsClient

            if not self.credential:
                raise ValueError(
                    "Azure credential is required. Initialize AzureProvider with "
                    "client_id, client_secret, and tenant_id."
                )

            return TextAnalyticsClient(
                endpoint=self.endpoint,
                credential=self.credential
            )
        except ImportError:
            raise ImportError(
                "Azure Text Analytics SDK not installed. "
                "Install with: pip install azure-ai-textanalytics azure-identity"
            )

    def detect_pii(self, text: str) -> List[Dict[str, Any]]:
        """
        Detect PII using Azure Text Analytics AI.

        Args:
            text: Text to analyze

        Returns:
            List of detected PII entities with metadata
        """
        client = self._get_client()

        try:
            # Call Azure Text Analytics PII Recognition
            response = client.recognize_pii_entities(
                documents=[{"id": "1", "language": self.language, "text": text}],
                language=self.language
            )

            entities = []
            for doc in response:
                if not doc.is_error:
                    for entity in doc.entities:
                        entities.append({
                            'text': entity.text,
                            'category': entity.category,  # e.g., "Person", "Email", "SSN"
                            'subcategory': entity.subcategory if hasattr(entity, 'subcategory') else None,
                            'confidence_score': entity.confidence_score,
                            'offset': entity.offset,
                            'length': entity.length
                        })
                else:
                    print(f"[Azure AI] Error in document: {doc.error}")

            return entities

        except Exception as e:
            print(f"[Azure AI] Error detecting PII: {e}")
            return []

    async def detect_pii_async(self, text: str) -> List[Dict[str, Any]]:
        """
        Async version of PII detection using Azure's native async client.

        Best Practice: Azure SDK has native async support (azure.ai.textanalytics.aio)
        which uses aiohttp under the hood with proper connection pooling.

        Args:
            text: Text to analyze

        Returns:
            List of detected PII entities
        """
        try:
            # Use Azure's native async client (recommended)
            return await self._detect_pii_with_azure_async(text)
        except Exception as e:
            # Fallback to ThreadPoolExecutor
            print(f"[Azure AI] Native async failed ({e}), using ThreadPoolExecutor fallback")
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(None, self.detect_pii, text)

    async def _detect_pii_with_azure_async(self, text: str) -> List[Dict[str, Any]]:
        """
        Detect PII using Azure's native async client.

        This is the BEST approach - Azure SDK provides native async support
        with proper connection pooling and retry logic built-in.
        """
        async with self._get_async_client() as client:
            try:
                response = await client.recognize_pii_entities(
                    documents=[{"id": "1", "language": self.language, "text": text}],
                    language=self.language
                )

                entities = []
                for doc in response:
                    if not doc.is_error:
                        for entity in doc.entities:
                            entities.append({
                                'text': entity.text,
                                'category': entity.category,
                                'subcategory': entity.subcategory if hasattr(entity, 'subcategory') else None,
                                'confidence_score': entity.confidence_score,
                                'offset': entity.offset,
                                'length': entity.length
                            })
                    else:
                        print(f"[Azure AI Async] Error in document: {doc.error}")

                return entities

            except Exception as e:
                print(f"[Azure AI Async] Error: {e}")
                raise

    async def close(self):
        """Close Azure client and release connections."""
        if self._client:
            await self._client.close()
            self._client = None

    def redact(self, text: str) -> RedactionResult:
        """
        Main redaction method using Azure AI detection.

        Args:
            text: Text to redact

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not text:
            return RedactionResult(redacted_text="", tokens=[])

        # Step 1: Detect PII using Azure AI (cloud)
        entities = self.detect_pii(text)

        print(f"[Azure AI] Detected {len(entities)} PII entities")

        # Step 2: Redact locally based on detection
        return self._redact_with_entities(text, entities)

    async def redact_async(self, text: str) -> RedactionResult:
        """
        Async redaction using Azure AI.

        Args:
            text: Text to redact

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not text:
            return RedactionResult(redacted_text="", tokens=[])

        # Step 1: Detect PII using Azure AI (async)
        entities = await self.detect_pii_async(text)

        print(f"[Azure AI Async] Detected {len(entities)} PII entities")

        # Step 2: Redact locally
        return self._redact_with_entities(text, entities)

    def _redact_with_entities(self, text: str, entities: List[Dict[str, Any]]) -> RedactionResult:
        """
        Redact text locally based on Azure AI detected entities.

        Args:
            text: Original text
            entities: Detected PII entities from Azure

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not entities:
            return RedactionResult(redacted_text=text, tokens=[])

        # Sort entities by offset in reverse order
        # This allows replacement from end to start without position issues
        sorted_entities = sorted(entities, key=lambda e: e['offset'], reverse=True)

        redacted_text = text
        tokens = []

        for entity in sorted_entities:
            start = entity['offset']
            end = start + entity['length']
            original_text = entity['text']
            category = entity['category']

            # Create unique token ID
            token_id_hash = hashlib.md5(
                f"{original_text}{start}".encode()
            ).hexdigest()[:8]

            replacement = f"[{category.upper()}_{token_id_hash}]"

            # Map Azure categories to RedactionType
            redaction_type = self._map_azure_category(category)

            # Create RedactionToken
            # Note: RedactionToken only accepts start_pos and end_pos (not position/metadata)
            token = RedactionToken(
                token_id=replacement,
                original_value=original_text,
                redaction_type=redaction_type,
                start_pos=start,
                end_pos=end
            )
            tokens.append(token)

            # Replace in text
            redacted_text = redacted_text[:start] + replacement + redacted_text[end:]

        return RedactionResult(
            redacted_text=redacted_text,
            tokens=tokens
        )

    def _map_azure_category(self, category: str) -> RedactionType:
        """
        Map Azure PII category to RedactionType enum.

        Args:
            category: Azure PII category

        Returns:
            Corresponding RedactionType
        """
        category_map = {
            'Email': RedactionType.EMAIL,
            'PhoneNumber': RedactionType.PHONE,
            'CreditCard': RedactionType.CREDIT_CARD,
            'IPAddress': RedactionType.IP_ADDRESS,
            'Person': RedactionType.CUSTOM,  # Person names
            'Organization': RedactionType.CUSTOM,
            'Address': RedactionType.CUSTOM,
            'SSN': RedactionType.SSN,
            'USSocialSecurityNumber': RedactionType.SSN,
        }

        return category_map.get(category, RedactionType.CUSTOM)
