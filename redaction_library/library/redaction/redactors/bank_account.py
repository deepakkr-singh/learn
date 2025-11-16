"""Bank account number redactor."""
import re
from ..base import BaseRedactor, RedactionType


class BankAccountRedactor(BaseRedactor):
    """Redactor for bank account numbers."""

    def __init__(self):
        super().__init__(RedactionType.BANK_ACCOUNT)

    def get_pattern(self) -> str:
        """Return the regex pattern for bank account numbers."""
        # Matches bank account numbers (8-17 digits, may include spaces/dashes)
        # Common formats: 12345678, 1234-5678-90, 1234 5678 9012 3456
        return r'\b\d{4}[-\s]?\d{4}[-\s]?\d{2,9}\b|\b\d{8,17}\b'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid bank account number.

        Args:
            text: The text to validate

        Returns:
            True if valid bank account number
        """
        # Remove all non-digit characters
        digits = re.sub(r'\D', '', text)

        # Bank account numbers are typically 8-17 digits
        if len(digits) < 8 or len(digits) > 17:
            return False

        # Check if all digits are the same (likely not a real account)
        if len(set(digits)) == 1:
            return False

        return True
