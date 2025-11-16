"""Main redaction service with sync and async support."""
from typing import List, Dict, Optional
from .base import BaseRedactor, RedactionResult, RedactionToken, BaseProvider
from .redactors import (
    EmailRedactor, PhoneRedactor, SSNRedactor, CreditCardRedactor,
    BankAccountRedactor, IPAddressRedactor, PassportRedactor
)
from .utils import TextChunker, ParallelProcessor
import asyncio


class RedactionService:
    """
    Main service for redacting sensitive information.

    Supports both sync and async operations with parallel processing.

    Async mode uses a hybrid approach for optimal performance:
    - Tiny text (< async_threshold): Runs synchronously for minimal latency
    - Medium text (>= async_threshold): Uses executor to keep event loop non-blocking
    - Large text (>= chunk_size): Chunks and processes in parallel

    Configure async_threshold based on your use case:
    - Low concurrency: Use higher threshold (1000-2000) to minimize overhead
    - High concurrency: Use lower threshold (0-500) to maximize throughput
    - Set to 0 to always use executor (recommended for production APIs)
    """

    def __init__(self,
                 provider: Optional[BaseProvider] = None,
                 redactors: Optional[List[BaseRedactor]] = None,
                 chunk_size: int = 5000,
                 parallel: bool = True,
                 max_workers: Optional[int] = None,
                 async_threshold: int = 1000,
                 use_cloud_detection: bool = False,
                 azure_text_analytics_endpoint: Optional[str] = None,
                 aws_region: Optional[str] = None):
        """
        Initialize the redaction service.

        Args:
            provider: Cloud provider for credentials (OPTIONAL - AWSProvider or AzureProvider).
                     Can be used for:
                     1. Fetching secrets from cloud secret managers (Key Vault, Secrets Manager)
                     2. Enabling cloud-based AI PII detection (when use_cloud_detection=True)
                     IMPORTANT: For Azure, provider must be initialized with client_id, client_secret, tenant_id
            redactors: List of redactors to use (default: all built-in redactors)
            chunk_size: Size of text chunks for large text processing (default: 5000 chars)
            parallel: Whether to enable parallel processing (default: True)
            max_workers: Maximum number of parallel workers (default: CPU count)
            async_threshold: Text size (in chars) above which async methods use executor.
                           Below this, runs synchronously for better latency.
                           Set to 0 to always use executor (high concurrency scenarios).
                           Default: 1000 chars
            use_cloud_detection: Use cloud AI for PII detection instead of local regex (default: False)
                                When True, uses Azure Text Analytics or AWS Comprehend based on provider
            azure_text_analytics_endpoint: Azure Text Analytics endpoint (required if using Azure cloud detection)
            aws_region: AWS region for Comprehend (default: 'us-east-1')
        """
        self.provider = provider
        self.chunk_size = chunk_size
        self.parallel = parallel
        self.async_threshold = async_threshold
        self.use_cloud_detection = use_cloud_detection

        # Cloud detector (Azure or AWS)
        self._cloud_detector = None

        # Initialize cloud detector if requested
        if use_cloud_detection:
            from .providers import AWSProvider, AzureProvider

            if isinstance(provider, AzureProvider):
                # Use Azure Text Analytics with Azure AD authentication
                if not azure_text_analytics_endpoint:
                    raise ValueError(
                        "Azure Text Analytics endpoint required for cloud detection. "
                        "Set AZURE_TEXT_ANALYTICS_ENDPOINT in .env"
                    )

                # Initialize provider to get credential
                provider.initialize()
                credential = provider.get_credential()

                from .cloud_detectors import AzureTextAnalyticsPIIDetector
                self._cloud_detector = AzureTextAnalyticsPIIDetector(
                    endpoint=azure_text_analytics_endpoint,
                    credential=credential
                )
                print("[RedactionService] Using Azure Text Analytics for PII detection (Azure AD authenticated)")

            elif isinstance(provider, AWSProvider) or aws_region:
                # Use AWS Comprehend
                region = aws_region or 'us-east-1'

                from .cloud_detectors import AWSComprehendPIIDetector
                self._cloud_detector = AWSComprehendPIIDetector(region=region)
                print("[RedactionService] Using AWS Comprehend for PII detection")

            else:
                print("[RedactionService] Warning: use_cloud_detection=True but no provider specified. Using local regex.")
                self.use_cloud_detection = False

        # Initialize redactors (only for local detection)
        if not use_cloud_detection:
            if redactors is None:
                self.redactors = [
                    EmailRedactor(),
                    PhoneRedactor(),
                    SSNRedactor(),
                    CreditCardRedactor(),
                    BankAccountRedactor(),
                    IPAddressRedactor(),
                    PassportRedactor()
                ]
            else:
                self.redactors = redactors
        else:
            self.redactors = redactors or []  # Cloud detection doesn't use redactors

        # Initialize utilities (no overlap)
        self.chunker = TextChunker(chunk_size=chunk_size, overlap=0)
        self.processor = ParallelProcessor(max_workers=max_workers)

        # Token storage for unmasking
        self._token_store: Dict[str, RedactionToken] = {}

    def add_redactor(self, redactor: BaseRedactor):
        """Add a custom redactor to the service."""
        self.redactors.append(redactor)

    def remove_redactor(self, redaction_type: str):
        """Remove a redactor by type."""
        self.redactors = [r for r in self.redactors if r.redaction_type.value != redaction_type]

    def redact(self, text: str, store_tokens: bool = True) -> RedactionResult:
        """
        Redact sensitive information from text (sync).

        Args:
            text: The text to redact
            store_tokens: Whether to store tokens for later unmasking

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not text:
            return RedactionResult(redacted_text="", tokens=[])

        # Check if text needs chunking
        if len(text) > self.chunk_size:
            return self._redact_chunked(text, store_tokens)
        else:
            return self._redact_single(text, 0, store_tokens)

    async def redact_async(self, text: str, store_tokens: bool = True) -> RedactionResult:
        """
        Redact sensitive information from text (async).

        Uses hybrid approach:
        - Tiny text (< async_threshold): Runs directly for minimal latency
        - Medium text (>= async_threshold, < chunk_size): Uses executor to avoid blocking
        - Large text (>= chunk_size): Chunks and processes in parallel with executor

        Args:
            text: The text to redact
            store_tokens: Whether to store tokens for later unmasking

        Returns:
            RedactionResult with redacted text and tokens
        """
        if not text:
            return RedactionResult(redacted_text="", tokens=[])

        # Check if text needs chunking
        if len(text) > self.chunk_size:
            # Large text - chunk and process in parallel
            return await self._redact_chunked_async(text, store_tokens)
        elif len(text) > self.async_threshold:
            # Medium text - use executor to avoid blocking event loop
            loop = asyncio.get_event_loop()
            return await loop.run_in_executor(
                None,
                self._redact_single,
                text,
                0,
                store_tokens
            )
        else:
            # Tiny text - run directly (faster, minimal blocking)
            return self._redact_single(text, 0, store_tokens)

    def _redact_single(self,
                      text: str,
                      start_pos: int,
                      store_tokens: bool) -> RedactionResult:
        """Redact a single chunk of text (sync)."""
        # Use cloud detection if enabled
        if self.use_cloud_detection and self._cloud_detector:
            result = self._cloud_detector.redact(text)
        else:
            # Use local regex-based detection
            result = RedactionResult(redacted_text=text, tokens=[])

            # Apply each redactor
            current_text = text
            for redactor in self.redactors:
                redacted, tokens = redactor.redact(current_text, start_pos)
                current_text = redacted
                result.tokens.extend(tokens)

            result.redacted_text = current_text

        # Store tokens if requested
        if store_tokens:
            for token in result.tokens:
                self._token_store[token.token_id] = token

        return result

    def _redact_chunked(self, text: str, store_tokens: bool) -> RedactionResult:
        """Redact large text using chunking (sync)."""
        # Split text into chunks
        chunks = self.chunker.chunk_text(text)

        if self.parallel and len(chunks) > 1:
            # Process chunks in parallel using ProcessPool (CPU-bound)
            def process_chunk(chunk_data):
                chunk_text, start_pos = chunk_data
                return self._redact_single(chunk_text, start_pos, False)

            chunk_results = self.processor.process_parallel(process_chunk, chunks, task_type='cpu')
        else:
            # Process chunks sequentially
            chunk_results = []
            for chunk_text, start_pos in chunks:
                result = self._redact_single(chunk_text, start_pos, False)
                chunk_results.append(result)

        # Merge results
        merged_result = self._merge_chunk_results(chunk_results, chunks)

        # Store tokens if requested
        if store_tokens:
            for token in merged_result.tokens:
                self._token_store[token.token_id] = token

        return merged_result

    async def _redact_chunked_async(self, text: str, store_tokens: bool) -> RedactionResult:
        """Redact large text using chunking (async)."""
        # Split text into chunks
        chunks = self.chunker.chunk_text(text)

        if self.parallel and len(chunks) > 1:
            # Process chunks in parallel using async
            async def process_chunk(chunk_data):
                chunk_text, start_pos = chunk_data
                # CPU-bound, but run in executor for true async
                loop = asyncio.get_event_loop()
                return await loop.run_in_executor(
                    None,
                    self._redact_single,
                    chunk_text,
                    start_pos,
                    False
                )

            chunk_results = await self.processor.process_async(process_chunk, chunks)
        else:
            # Process chunks sequentially (no async benefit)
            chunk_results = []
            for chunk_text, start_pos in chunks:
                result = self._redact_single(chunk_text, start_pos, False)
                chunk_results.append(result)

        # Merge results
        merged_result = self._merge_chunk_results(chunk_results, chunks)

        # Store tokens if requested
        if store_tokens:
            for token in merged_result.tokens:
                self._token_store[token.token_id] = token

        return merged_result

    def _merge_chunk_results(self,
                            chunk_results: List[RedactionResult],
                            chunks: List[tuple]) -> RedactionResult:
        """Merge results from multiple chunks."""
        if not chunk_results:
            return RedactionResult(redacted_text="", tokens=[])

        if len(chunk_results) == 1:
            return chunk_results[0]

        # Prepare data for chunker merge
        merge_data = [
            (result.redacted_text, chunks[i][1], result.tokens)
            for i, result in enumerate(chunk_results)
        ]

        merged_text, all_tokens = self.chunker.merge_results(merge_data)

        return RedactionResult(
            redacted_text=merged_text,
            tokens=all_tokens
        )

    def unmask(self, redacted_text: str, tokens: Optional[List[RedactionToken]] = None) -> str:
        """
        Unmask redacted text back to original.

        Args:
            redacted_text: The redacted text
            tokens: Optional list of tokens (uses stored tokens if not provided)

        Returns:
            Original unredacted text
        """
        if tokens is None:
            # Use stored tokens
            tokens = list(self._token_store.values())

        if not tokens:
            return redacted_text

        # Sort tokens by start position in reverse to maintain positions
        sorted_tokens = sorted(tokens, key=lambda t: t.start_pos, reverse=True)

        result = redacted_text
        for token in sorted_tokens:
            # Replace token with original value
            result = result.replace(token.token_id, token.original_value, 1)

        return result

    def get_token_map(self) -> Dict[str, str]:
        """
        Get the mapping of token IDs to original values.

        Returns:
            Dictionary mapping token IDs to original values
        """
        return {token_id: token.original_value for token_id, token in self._token_store.items()}

    def clear_token_store(self):
        """Clear the stored tokens."""
        self._token_store.clear()

    def batch_redact(self, texts: List[str], store_tokens: bool = True) -> List[RedactionResult]:
        """
        Redact multiple texts in parallel (sync).

        Args:
            texts: List of texts to redact
            store_tokens: Whether to store tokens for later unmasking

        Returns:
            List of RedactionResults
        """
        if self.parallel:
            return self.processor.process_parallel(self.redact, texts, task_type='cpu', store_tokens=store_tokens)
        else:
            return [self.redact(text, store_tokens) for text in texts]

    async def batch_redact_async(self,
                                 texts: List[str],
                                 store_tokens: bool = True) -> List[RedactionResult]:
        """
        Redact multiple texts in parallel (async).

        Args:
            texts: List of texts to redact
            store_tokens: Whether to store tokens for later unmasking

        Returns:
            List of RedactionResults
        """
        if self.parallel:
            return await self.processor.process_async(self.redact_async, texts, store_tokens)
        else:
            results = []
            for text in texts:
                result = await self.redact_async(text, store_tokens)
                results.append(result)
            return results
