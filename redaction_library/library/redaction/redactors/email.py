"""Email redactor."""
from ..base import BaseRedactor, RedactionType


class EmailRedactor(BaseRedactor):
    """Redactor for email addresses."""

    def __init__(self):
        super().__init__(RedactionType.EMAIL)

    def get_pattern(self) -> str:
        """Return the regex pattern for email addresses."""
        # Comprehensive email pattern
        return r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid email address.

        Args:
            text: The text to validate

        Returns:
            True if valid email
        """
        # Basic validation - has @ and domain
        if '@' not in text:
            return False

        parts = text.split('@')
        if len(parts) != 2:
            return False

        local_part, domain = parts

        # Check local part
        if not local_part or len(local_part) > 64:
            return False

        # Check domain
        if not domain or '.' not in domain:
            return False

        return True
