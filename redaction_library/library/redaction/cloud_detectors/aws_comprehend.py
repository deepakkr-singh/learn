"""
AWS Comprehend PII Detection

Uses AWS Comprehend API for AI-powered PII detection.
Detection happens in AWS cloud, redaction happens locally.

Best Practices Implemented:
- I/O-bound operations: Uses aioboto3 for true async AWS API calls
- Fallback: ThreadPoolExecutor when aioboto3 not available
- Connection pooling: aioboto3 handles connection reuse automatically
"""

from typing import List, Dict, Any, Optional
from ..base import RedactionResult, RedactionToken, RedactionType
import hashlib
import asyncio


class AWSComprehendPIIDetector:
    """
    AWS Comprehend AI-powered PII detector.

    Flow:
    1. Send text to AWS Comprehend API (cloud detection)
    2. Receive PII entities with positions and confidence scores
    3. Redact locally based on AWS's AI detection results

    AWS Setup Required:
    1. AWS account with Comprehend access
    2. IAM role or access keys configured
    3. Add to .env (optional):
       AWS_ACCESS_KEY_ID=your_access_key
       AWS_SECRET_ACCESS_KEY=your_secret_key
       AWS_REGION=us-east-1
    """

    def __init__(self, region: str = 'us-east-1', language_code: str = 'en'):
        """
        Initialize AWS Comprehend PII detector.

        Args:
            region: AWS region
            language_code: Language code (default: 'en')
        """
        self.region = region
        self.language_code = language_code
        self._client = None
        self._session: Optional[Any] = None  # aioboto3 session

    def _get_client(self):
        """Lazy initialization of AWS Comprehend client."""
        if self._client is None:
            try:
                import boto3
                self._client = boto3.client('comprehend', region_name=self.region)
            except ImportError:
                raise ImportError(
                    "boto3 not installed. Install with: pip install boto3"
                )
        return self._client

    def detect_pii(self, text: str) -> List[Dict[str, Any]]:
        """
        Detect PII using AWS Comprehend AI.

        Args:
            text: Text to analyze

        Returns:
            List of detected PII entities with metadata
        """
        client = self._get_client()

        try:
            # Call AWS Comprehend PII Detection
            response = client.detect_pii_entities(
                Text=text,
                LanguageCode=self.language_code
            )

            entities = []
            if 'Entities' in response:
                for entity in response['Entities']:
                    # Extract entity text from original text using offsets
                    begin_offset = entity['BeginOffset']
                    end_offset = entity['EndOffset']
                    entity_text = text[begin_offset:end_offset]

                    entities.append({
                        'text': entity_text,
                        'type': entity['Type'],  # e.g., "EMAIL", "NAME", "SSN"
                        'score': entity['Score'],  # Confidence score
                        'begin_offset': begin_offset,
                        'end_offset': end_offset
                    })

            return entities

        except Exception as e:
            print(f"[AWS Comprehend] Error detecting PII: {e}")
            return []

    async def detect_pii_async(self, text: str) -> List[Dict[str, Any]]:
        """
        Async version of PII detection using aioboto3 (true async I/O).

        Best Practice: I/O-bound operations (AWS API calls) use aioboto3 for true async,
        NOT ThreadPoolExecutor which is for CPU-bound tasks.

        Args:
            text: Text to analyze

        Returns:
            List of detected PII entities
        """
        try:
            import aioboto3
            return await self._detect_pii_with_aioboto3(text)
        except ImportError:
            # Fallback to ThreadPoolExecutor if aioboto3 not available
            print("[AWS Comprehend] aioboto3 not available, using ThreadPoolExecutor fallback")
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(None, self.detect_pii, text)

    async def _detect_pii_with_aioboto3(self, text: str) -> List[Dict[str, Any]]:
        """
        Detect PII using aioboto3 for true async AWS API calls.

        aioboto3 provides native async support for boto3 with connection pooling.
        """
        import aioboto3

        # Create session if not exists (reused for connection pooling)
        if self._session is None:
            self._session = aioboto3.Session()

        try:
            async with self._session.client('comprehend', region_name=self.region) as client:
                response = await client.detect_pii_entities(
                    Text=text,
                    LanguageCode=self.language_code
                )

                entities = []
                if 'Entities' in response:
                    for entity in response['Entities']:
                        begin_offset = entity['BeginOffset']
                        end_offset = entity['EndOffset']
                        entity_text = text[begin_offset:end_offset]

                        entities.append({
                            'text': entity_text,
                            'type': entity['Type'],
                            'score': entity['Score'],
                            'begin_offset': begin_offset,
                            'end_offset': end_offset
                        })

                return entities

        except Exception as e:
            print(f"[AWS Comprehend Async] Error: {e}")
            return []

    async def close(self):
        """Close aioboto3 session and release connections."""
        # aioboto3 sessions are context-managed, no explicit close needed
        self._session = None

    def redact(self, text: str) -> RedactionResult:
        """
        Main redaction method using AWS Comprehend detection.

        Args:
            text: Text to redact

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not text:
            return RedactionResult(redacted_text="", tokens=[])

        # Step 1: Detect PII using AWS Comprehend (cloud)
        entities = self.detect_pii(text)

        print(f"[AWS Comprehend] Detected {len(entities)} PII entities")

        # Step 2: Redact locally based on detection
        return self._redact_with_entities(text, entities)

    async def redact_async(self, text: str) -> RedactionResult:
        """
        Async redaction using AWS Comprehend.

        Args:
            text: Text to redact

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not text:
            return RedactionResult(redacted_text="", tokens=[])

        # Step 1: Detect PII using AWS Comprehend (async)
        entities = await self.detect_pii_async(text)

        print(f"[AWS Comprehend Async] Detected {len(entities)} PII entities")

        # Step 2: Redact locally
        return self._redact_with_entities(text, entities)

    def _redact_with_entities(self, text: str, entities: List[Dict[str, Any]]) -> RedactionResult:
        """
        Redact text locally based on AWS Comprehend detected entities.

        Args:
            text: Original text
            entities: Detected PII entities from AWS

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not entities:
            return RedactionResult(redacted_text=text, tokens=[])

        # Sort entities by offset in reverse order
        sorted_entities = sorted(entities, key=lambda e: e['begin_offset'], reverse=True)

        redacted_text = text
        tokens = []

        for entity in sorted_entities:
            start = entity['begin_offset']
            end = entity['end_offset']
            original_text = entity['text']
            pii_type = entity['type']

            # Create unique token ID
            token_id_hash = hashlib.md5(
                f"{original_text}{start}".encode()
            ).hexdigest()[:8]

            replacement = f"[{pii_type.upper()}_{token_id_hash}]"

            # Map AWS type to RedactionType
            redaction_type = self._map_aws_type(pii_type)

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

    def _map_aws_type(self, pii_type: str) -> RedactionType:
        """
        Map AWS Comprehend PII type to RedactionType enum.

        Args:
            pii_type: AWS PII type

        Returns:
            Corresponding RedactionType
        """
        type_map = {
            'EMAIL': RedactionType.EMAIL,
            'PHONE': RedactionType.PHONE,
            'SSN': RedactionType.SSN,
            'CREDIT_DEBIT_NUMBER': RedactionType.CREDIT_CARD,
            'CREDIT_DEBIT_CVV': RedactionType.CREDIT_CARD,
            'CREDIT_DEBIT_EXPIRY': RedactionType.CREDIT_CARD,
            'IP_ADDRESS': RedactionType.IP_ADDRESS,
            'PASSPORT_NUMBER': RedactionType.PASSPORT,
            'BANK_ACCOUNT_NUMBER': RedactionType.BANK_ACCOUNT,
            'BANK_ROUTING': RedactionType.BANK_ACCOUNT,
            'NAME': RedactionType.CUSTOM,
            'ADDRESS': RedactionType.CUSTOM,
            'USERNAME': RedactionType.CUSTOM,
            'PASSWORD': RedactionType.CUSTOM,
            'DRIVER_ID': RedactionType.CUSTOM,
            'PIN': RedactionType.CUSTOM,
            'DATE_TIME': RedactionType.CUSTOM,
            'AGE': RedactionType.CUSTOM,
            'URL': RedactionType.CUSTOM,
        }

        return type_map.get(pii_type, RedactionType.CUSTOM)
