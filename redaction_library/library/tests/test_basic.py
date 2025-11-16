"""
Basic tests for the redaction library.
Run with: python -m pytest tests/test_basic.py -v
"""
import pytest
import asyncio
from redaction_library import (
    RedactionService,
    EmailRedactor,
    PhoneRedactor,
    SSNRedactor,
    CreditCardRedactor
)


class TestEmailRedactor:
    """Test email redaction."""

    def test_simple_email(self):
        redactor = EmailRedactor()
        text = "Contact me at john@example.com"
        redacted, tokens = redactor.redact(text)

        assert len(tokens) == 1
        assert tokens[0].original_value == "john@example.com"
        assert "john@example.com" not in redacted

    def test_multiple_emails(self):
        redactor = EmailRedactor()
        text = "Email john@example.com or jane@company.org"
        redacted, tokens = redactor.redact(text)

        assert len(tokens) == 2
        assert "john@example.com" not in redacted
        assert "jane@company.org" not in redacted


class TestPhoneRedactor:
    """Test phone number redaction."""

    def test_formatted_phone(self):
        redactor = PhoneRedactor()
        text = "Call (555) 123-4567"
        redacted, tokens = redactor.redact(text)

        assert len(tokens) == 1
        assert tokens[0].original_value == "(555) 123-4567"

    def test_unformatted_phone(self):
        redactor = PhoneRedactor()
        text = "Phone: 5551234567"
        redacted, tokens = redactor.redact(text)

        assert len(tokens) == 1


class TestSSNRedactor:
    """Test SSN redaction."""

    def test_formatted_ssn(self):
        redactor = SSNRedactor()
        text = "SSN: 123-45-6789"
        redacted, tokens = redactor.redact(text)

        assert len(tokens) == 1
        assert tokens[0].original_value == "123-45-6789"

    def test_invalid_ssn(self):
        redactor = SSNRedactor()
        # 000 is invalid
        text = "SSN: 000-12-3456"
        redacted, tokens = redactor.redact(text)

        # Should not redact invalid SSN
        assert len(tokens) == 0


class TestCreditCardRedactor:
    """Test credit card redaction."""

    def test_valid_credit_card(self):
        redactor = CreditCardRedactor()
        # Valid Visa number
        text = "Card: 4532-1488-0343-6467"
        redacted, tokens = redactor.redact(text)

        assert len(tokens) == 1
        assert "4532-1488-0343-6467" not in redacted

    def test_invalid_credit_card(self):
        redactor = CreditCardRedactor()
        # Invalid Luhn checksum
        text = "Card: 1234-5678-9012-3456"
        redacted, tokens = redactor.redact(text)

        # Should not redact invalid card
        assert len(tokens) == 0


class TestRedactionService:
    """Test the main redaction service."""

    def test_basic_redaction(self):
        service = RedactionService()
        text = "Email: john@example.com, Phone: 555-123-4567"
        result = service.redact(text)

        assert len(result.tokens) >= 2
        assert "john@example.com" not in result.redacted_text
        assert "555-123-4567" not in result.redacted_text

    def test_unmask(self):
        service = RedactionService()
        text = "Contact: john@example.com"
        result = service.redact(text, store_tokens=True)

        # Unmask
        original = service.unmask(result.redacted_text, result.tokens)

        assert "john@example.com" in original

    def test_batch_redact(self):
        service = RedactionService()
        texts = [
            "Email: user1@example.com",
            "Phone: 555-111-2222",
            "SSN: 123-45-6789"
        ]

        results = service.batch_redact(texts)

        assert len(results) == 3
        for result in results:
            assert len(result.tokens) >= 1

    def test_custom_redactors(self):
        # Only use email redactor
        service = RedactionService(redactors=[EmailRedactor()])
        text = "Email: john@example.com, Phone: 555-123-4567"
        result = service.redact(text)

        # Should only redact email
        assert "john@example.com" not in result.redacted_text
        assert "555-123-4567" in result.redacted_text

    def test_large_text_chunking(self):
        service = RedactionService(chunk_size=1000)

        # Generate large text
        large_text = ""
        for i in range(50):
            large_text += f"Email {i}: user{i}@example.com, "

        result = service.redact(large_text)

        # Should find all emails
        assert len(result.tokens) >= 50


class TestAsyncRedaction:
    """Test async redaction operations."""

    @pytest.mark.asyncio
    async def test_async_basic(self):
        service = RedactionService()
        text = "Email: john@example.com"
        result = await service.redact_async(text)

        assert len(result.tokens) >= 1
        assert "john@example.com" not in result.redacted_text

    @pytest.mark.asyncio
    async def test_async_batch(self):
        service = RedactionService()
        texts = [
            "Email: user1@example.com",
            "Phone: 555-111-2222",
            "SSN: 123-45-6789"
        ]

        results = await service.batch_redact_async(texts)

        assert len(results) == 3
        for result in results:
            assert len(result.tokens) >= 1

    @pytest.mark.asyncio
    async def test_concurrent_operations(self):
        service = RedactionService()

        # Run multiple operations concurrently
        tasks = [
            service.redact_async("Email: user1@example.com"),
            service.redact_async("Phone: 555-111-2222"),
            service.redact_async("SSN: 123-45-6789"),
        ]

        results = await asyncio.gather(*tasks)

        assert len(results) == 3
        for result in results:
            assert len(result.tokens) >= 1


class TestTokenManagement:
    """Test token storage and management."""

    def test_token_storage(self):
        service = RedactionService()
        text = "Email: john@example.com"

        result = service.redact(text, store_tokens=True)

        # Check token is stored
        token_map = service.get_token_map()
        assert len(token_map) >= 1

    def test_clear_tokens(self):
        service = RedactionService()
        text = "Email: john@example.com"

        service.redact(text, store_tokens=True)
        assert len(service.get_token_map()) >= 1

        service.clear_token_store()
        assert len(service.get_token_map()) == 0

    def test_unmask_without_storage(self):
        service = RedactionService()
        text = "Email: john@example.com"

        # Don't store tokens
        result = service.redact(text, store_tokens=False)

        # Unmask using result tokens
        original = service.unmask(result.redacted_text, result.tokens)
        assert "john@example.com" in original


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
