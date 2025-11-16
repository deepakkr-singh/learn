"""IP address redactor."""
from ..base import BaseRedactor, RedactionType


class IPAddressRedactor(BaseRedactor):
    """Redactor for IP addresses (IPv4 and IPv6)."""

    def __init__(self):
        super().__init__(RedactionType.IP_ADDRESS)

    def get_pattern(self) -> str:
        """Return the regex pattern for IP addresses."""
        # Matches both IPv4 and IPv6
        ipv4_pattern = r'\b(?:\d{1,3}\.){3}\d{1,3}\b'
        ipv6_pattern = r'\b(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\b|\b(?:[0-9a-fA-F]{1,4}:){1,7}:\b|\b(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}\b'

        return f'({ipv4_pattern})|({ipv6_pattern})'

    def validate(self, text: str) -> bool:
        """
        Validate if the text is a valid IP address.

        Args:
            text: The text to validate

        Returns:
            True if valid IP address
        """
        # Try to validate as IPv4
        if self._validate_ipv4(text):
            return True

        # Try to validate as IPv6
        if self._validate_ipv6(text):
            return True

        return False

    def _validate_ipv4(self, text: str) -> bool:
        """Validate IPv4 address."""
        parts = text.split('.')
        if len(parts) != 4:
            return False

        try:
            for part in parts:
                num = int(part)
                if num < 0 or num > 255:
                    return False
            return True
        except ValueError:
            return False

    def _validate_ipv6(self, text: str) -> bool:
        """Validate IPv6 address."""
        # Basic IPv6 validation
        if '::' in text:
            # Compressed format
            parts = text.split('::')
            if len(parts) > 2:
                return False
        else:
            # Full format
            parts = text.split(':')
            if len(parts) != 8:
                return False

        # Validate each part is valid hex
        for part in text.replace('::', ':').split(':'):
            if part:
                try:
                    int(part, 16)
                    if len(part) > 4:
                        return False
                except ValueError:
                    return False

        return True
