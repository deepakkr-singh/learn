"""
Redaction Library - Compact Examples
All essential usage patterns in one file.
"""

import os
import asyncio
from dotenv import load_dotenv
from redaction import RedactionService, AzureProvider, AWSProvider
from redaction.redactors import EmailRedactor
from redaction.base import BaseRedactor, RedactionType

load_dotenv()


# ============================================================================
# EXAMPLE 1: Basic Local Regex Redaction (No Provider)
# ============================================================================
def example_basic():
    """Basic redaction with local regex (no cloud, no provider)."""
    print("\n" + "=" * 60)
    print("EXAMPLE 1: Basic Local Regex")
    print("=" * 60)

    service = RedactionService()
    text = "Email: john@example.com, Phone: (555) 123-4567, SSN: 123-45-6789"
    result = service.redact(text)

    print(f"Original: {text}")
    print(f"Redacted: {result.redacted_text}")
    print(f"Found: {len(result.tokens)} PII items")


# ============================================================================
# EXAMPLE 2: Async Redaction
# ============================================================================
async def example_async():
    """Async redaction for high concurrency."""
    print("\n" + "=" * 60)
    print("EXAMPLE 2: Async Redaction")
    print("=" * 60)

    service = RedactionService(async_threshold=0)  # Always async

    texts = [
        "User 1: alice@example.com",
        "User 2: bob@example.com",
        "User 3: charlie@example.com"
    ]

    # Batch process asynchronously
    results = await service.batch_redact_async(texts)

    for i, result in enumerate(results):
        print(f"Text {i+1}: {result.redacted_text} ({len(result.tokens)} items)")


# ============================================================================
# EXAMPLE 3: Azure Cloud AI Detection (with Key Vault)
# ============================================================================
async def example_azure_ai():
    """Azure Text Analytics AI detection with Azure AD authentication."""
    print("\n" + "=" * 60)
    print("EXAMPLE 3: Azure AI Detection (with Key Vault)")
    print("=" * 60)

    # Import SecretManager
    from redaction.secrets.secret_manager import SecretManager

    # Configure secret source
    # Option 1: Default - env only (will skip if not found)
    # secret_manager = SecretManager(secret_source="env")

    # Option 2: Env with Key Vault fallback (recommended)
    # If secrets are in env, use them. If not, fetch from Key Vault and cache.
    secret_manager = SecretManager(
        secret_source="env",
        fallback_provider="keyvault",
        vault_url=os.getenv('AZURE_KEY_VAULT_URL', 'https://redactionkvdevnjnolfqc.vault.azure.net/'),
        use_managed_identity=True  # Use Azure CLI/Managed Identity for auth
    )

    # Option 3: Always fetch from Key Vault (fresh secrets every time)
    # secret_manager = SecretManager(
    #     secret_source="keyvault",
    #     vault_url=os.getenv('AZURE_KEY_VAULT_URL', 'https://redactionkvdevnjnolfqc.vault.azure.net/'),
    #     use_managed_identity=True
    # )

    # Get secrets
    try:
        secrets = secret_manager.get_azure_secrets()

        if not all(secrets.values()):
            print("⚠️  Azure credentials not available. Skipping.")
            return

        # Initialize with Azure AD (secure)
        provider = AzureProvider(
            client_id=secrets['AZURE_CLIENT_ID'],
            client_secret=secrets['AZURE_CLIENT_SECRET'],
            tenant_id=secrets['AZURE_TENANT_ID']
        )

        service = RedactionService(
            provider=provider,
            use_cloud_detection=True,
            azure_text_analytics_endpoint=secrets['AZURE_TEXT_ANALYTICS_ENDPOINT']
        )

        text = "Hi, I'm John Smith. Email: john@microsoft.com, Phone: (425) 555-0123"
        result = await service.redact_async(text)

        print(f"Original: {text}")
        print(f"Redacted: {result.redacted_text}")
        print(f"Detected by Azure AI: {len(result.tokens)} items")

    except ValueError as e:
        print(f"⚠️  {e}")
        print("⚠️  Skipping Azure example.")
        return


# ============================================================================
# EXAMPLE 4: AWS Cloud AI Detection
# ============================================================================
async def example_aws_ai():
    """AWS Comprehend AI detection."""
    print("\n" + "=" * 60)
    print("EXAMPLE 4: AWS AI Detection")
    print("=" * 60)

    # Check credentials
    if not os.getenv('AWS_ACCESS_KEY_ID'):
        print("⚠️  AWS credentials not configured. Skipping.")
        return

    provider = AWSProvider(region='us-east-1')

    service = RedactionService(
        provider=provider,
        use_cloud_detection=True,
        aws_region='us-east-1'
    )

    text = "Customer: Jane Anderson, Email: jane@company.com, Phone: 206-555-0199"
    result = await service.redact_async(text)

    print(f"Original: {text}")
    print(f"Redacted: {result.redacted_text}")
    print(f"Detected by AWS AI: {len(result.tokens)} items")


# ============================================================================
# EXAMPLE 5: Unmask (Restore Original)
# ============================================================================
def example_unmask():
    """Unmask redacted text back to original."""
    print("\n" + "=" * 60)
    print("EXAMPLE 5: Unmask (Restore Original)")
    print("=" * 60)

    service = RedactionService()

    text = "Contact: admin@example.com"
    result = service.redact(text, store_tokens=True)

    print(f"Original:  {text}")
    print(f"Redacted:  {result.redacted_text}")

    # Restore original
    original = service.unmask(result.redacted_text, result.tokens)
    print(f"Unmasked:  {original}")


# ============================================================================
# EXAMPLE 6: Custom Redactor
# ============================================================================
def example_custom_redactor():
    """Create custom redactor for specific patterns."""
    print("\n" + "=" * 60)
    print("EXAMPLE 6: Custom Redactor")
    print("=" * 60)

    class EmployeeIDRedactor(BaseRedactor):
        def __init__(self):
            super().__init__(RedactionType.CUSTOM, pattern=r'\b(EMP-\d{6})\b')

        def get_pattern(self) -> str:
            return r'\b(EMP-\d{6})\b'

        def validate(self, text: str) -> bool:
            # Basic validation - check format
            import re
            return bool(re.match(r'EMP-\d{6}', text))

    service = RedactionService(redactors=[EmployeeIDRedactor(), EmailRedactor()])

    text = "Employee EMP-123456 reported issue. Contact: emp@company.com"
    result = service.redact(text)

    print(f"Original: {text}")
    print(f"Redacted: {result.redacted_text}")


# ============================================================================
# EXAMPLE 7: High-Performance Batch Processing
# ============================================================================
async def example_high_performance():
    """Process large batches with parallel processing."""
    print("\n" + "=" * 60)
    print("EXAMPLE 7: High-Performance Batch")
    print("=" * 60)

    service = RedactionService(
        parallel=True,           # Enable ProcessPool
        max_workers=8,           # Use 8 CPU cores
        async_threshold=0        # Always async
    )

    # Generate test data
    texts = [f"Email: user{i}@example.com" for i in range(100)]

    import time
    start = time.time()
    results = await service.batch_redact_async(texts)
    elapsed = time.time() - start

    print(f"Processed: {len(texts)} texts")
    print(f"Time: {elapsed:.2f}s")
    print(f"Throughput: {len(texts)/elapsed:.0f} texts/sec")


# ============================================================================
# EXAMPLE 8: Azure with Key Vault (Production)
# ============================================================================
async def example_azure_keyvault():
    """Azure with Key Vault for production secrets management."""
    print("\n" + "=" * 60)
    print("EXAMPLE 8: Azure with Key Vault")
    print("=" * 60)

    if not os.getenv('AZURE_KEY_VAULT_URL'):
        print("⚠️  Key Vault not configured. Skipping.")
        return

    provider = AzureProvider(
        client_id=os.getenv('AZURE_CLIENT_ID'),
        client_secret=os.getenv('AZURE_CLIENT_SECRET'),
        tenant_id=os.getenv('AZURE_TENANT_ID'),
        vault_url=os.getenv('AZURE_KEY_VAULT_URL')
    )

    # Fetch secret from Key Vault
    secret = await provider.get_secret_async('my-api-key')
    print(f"Fetched secret from Key Vault: {secret.get('value', 'N/A')[:10]}...")


# ============================================================================
# Main
# ============================================================================
def main():
    """Run all examples."""
    print("\n" + "█" * 60)
    print("REDACTION LIBRARY - EXAMPLES")
    print("█" * 60)

    # Sync examples
    example_basic()
    example_unmask()
    example_custom_redactor()

    # Async examples
    asyncio.run(example_async())
    asyncio.run(example_azure_ai())
    # asyncio.run(example_aws_ai())
    asyncio.run(example_high_performance())
    # asyncio.run(example_azure_keyvault())

    print("\n" + "=" * 60)
    print("All examples completed!")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
