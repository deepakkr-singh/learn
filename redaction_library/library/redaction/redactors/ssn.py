"""Social Security Number redactor."""
import re
from ..base import BaseRedactor, RedactionType


class SSNRedactor(BaseRedactor):
    """Redactor for Social Security Numbers."""

    def __init__(self):
        super().__init__(RedactionType.SSN)

    def get_pattern(self) -> str:
        """Return the regex pattern for SSN."""
        # Matches formats: 123-45-6789, 123 45 6789, 123456789
        return r'\b\d{3}[-\s]?\d{2}[-\s]?\d{4}\b'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid SSN.

        Args:
            text: The text to validate

        Returns:
            True if valid SSN
        """
        # Remove all non-digit characters
        digits = re.sub(r'\D', '', text)

        # SSN must be exactly 9 digits
        if len(digits) != 9:
            return False

        # Check for invalid SSNs
        # First three digits cannot be 000, 666, or 900-999
        area = int(digits[:3])
        if area == 0 or area == 666 or area >= 900:
            return False

        # Middle two digits cannot be 00
        group = int(digits[3:5])
        if group == 0:
            return False

        # Last four digits cannot be 0000
        serial = int(digits[5:9])
        if serial == 0:
            return False

        return True
