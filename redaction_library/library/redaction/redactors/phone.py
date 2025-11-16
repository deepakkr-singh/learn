"""Phone number redactor."""
import re
from ..base import BaseRedactor, RedactionType


class PhoneRedactor(BaseRedactor):
    """Redactor for phone numbers."""

    def __init__(self):
        super().__init__(RedactionType.PHONE)

    def get_pattern(self) -> str:
        """Return the regex pattern for phone numbers."""
        # Matches various phone formats:
        # (123) 456-7890, 123-456-7890, 123.456.7890, 1234567890, +1 123 456 7890
        return r'(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid phone number.

        Args:
            text: The text to validate

        Returns:
            True if valid phone number
        """
        # Remove all non-digit characters
        digits = re.sub(r'\D', '', text)

        # US phone numbers should have 10 or 11 digits (with country code)
        if len(digits) in [10, 11]:
            return True

        return False
