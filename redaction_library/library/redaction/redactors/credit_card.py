"""Credit card number redactor."""
import re
from ..base import BaseRedactor, RedactionType


class CreditCardRedactor(BaseRedactor):
    """Redactor for credit card numbers."""

    def __init__(self):
        super().__init__(RedactionType.CREDIT_CARD)

    def get_pattern(self) -> str:
        """Return the regex pattern for credit card numbers."""
        # Matches formats: 1234-5678-9012-3456, 1234 5678 9012 3456, 1234567890123456
        return r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid credit card number using Luhn algorithm.

        Args:
            text: The text to validate

        Returns:
            True if valid credit card number
        """
        # Remove all non-digit characters
        digits = re.sub(r'\D', '', text)

        # Credit card numbers are typically 13-19 digits
        if len(digits) < 13 or len(digits) > 19:
            return False

        # Luhn algorithm
        def luhn_checksum(card_number):
            def digits_of(n):
                return [int(d) for d in str(n)]

            digits = digits_of(card_number)
            odd_digits = digits[-1::-2]
            even_digits = digits[-2::-2]
            checksum = sum(odd_digits)
            for d in even_digits:
                checksum += sum(digits_of(d * 2))
            return checksum % 10

        return luhn_checksum(digits) == 0
