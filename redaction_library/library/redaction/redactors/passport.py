"""Passport number redactor."""
from ..base import BaseRedactor, RedactionType


class PassportRedactor(BaseRedactor):
    """Redactor for passport numbers."""

    def __init__(self):
        super().__init__(RedactionType.PASSPORT)

    def get_pattern(self) -> str:
        """Return the regex pattern for passport numbers."""
        # Matches various passport formats:
        # US: 9 digits or 1 letter + 8 digits
        # UK: 9 digits
        # Most countries: 6-9 alphanumeric characters
        return r'\b[A-Z]{1,2}\d{6,9}\b|\b\d{9}\b|\b[A-Z0-9]{6,9}\b'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid passport number.

        Args:
            text: The text to validate

        Returns:
            True if valid passport number
        """
        # Remove spaces
        clean_text = text.replace(' ', '')

        # Check length (most passports are 6-9 characters)
        if len(clean_text) < 6 or len(clean_text) > 9:
            return False

        # Must contain at least one letter or be all digits
        has_letter = any(c.isalpha() for c in clean_text)
        all_digits = clean_text.isdigit()

        if not (has_letter or all_digits):
            return False

        # Check if all characters are alphanumeric
        if not clean_text.isalnum():
            return False

        return True
