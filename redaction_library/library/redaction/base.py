"""
Base classes and interfaces for the redaction library.
"""
from abc import ABC, abstractmethod
from typing import Dict, List, Optional, Tuple, Any, Union
from dataclasses import dataclass, field
from enum import Enum
import re


class RedactionType(Enum):
    """Types of redaction patterns."""
    EMAIL = "email"
    PHONE = "phone"
    SSN = "ssn"
    CREDIT_CARD = "credit_card"
    BANK_ACCOUNT = "bank_account"
    IP_ADDRESS = "ip_address"
    PASSPORT = "passport"
    CUSTOM = "custom"


@dataclass
class RedactionToken:
    """Token representing a redacted piece of information."""
    token_id: str
    original_value: str
    redaction_type: Union[RedactionType, Enum]
    start_pos: int
    end_pos: int


@dataclass
class RedactionResult:
    """Result of a redaction operation."""
    redacted_text: str
    tokens: List[RedactionToken] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def add_token(self, token: RedactionToken):
        """Add a redaction token to the result."""
        self.tokens.append(token)

    def get_token_map(self) -> Dict[str, str]:
        """Get a mapping of token IDs to original values."""
        return {token.token_id: token.original_value for token in self.tokens}


class BaseRedactor(ABC):
    """Base class for all redactors."""

    def __init__(self, redaction_type: Union[RedactionType, Enum], pattern: Optional[str] = None):
        """
        Initialize the redactor.

        Args:
            redaction_type: Either a built-in RedactionType or a custom Enum type.
                          Custom enums allow distinct token prefixes like [EMPLOYEE_ID_xxx].
            pattern: Optional pre-compiled pattern (if None, get_pattern() will be called)
        """
        self.redaction_type = redaction_type
        self.pattern = pattern
        self._compiled_pattern = re.compile(pattern) if pattern else None

    @abstractmethod
    def get_pattern(self) -> str:
        """Return the regex pattern for this redactor."""
        pass

    @abstractmethod
    def validate(self, text: str) -> bool:
        """Validate if the text matches the expected pattern."""
        pass

    def generate_token_id(self, original_value: str, position: int) -> str:
        """
        Generate a unique token ID for a redacted value.

        For built-in types: [EMAIL_a3f4d9e1]
        For custom enums: [EMPLOYEE_ID_a3f4d9e1]

        Args:
            original_value: The original PII value
            position: Position in text

        Returns:
            Unique token ID string
        """
        import hashlib

        # Get the enum value (works for both RedactionType and custom Enum)
        type_value = self.redaction_type.value

        # Create unique string for hashing
        unique_str = f"{original_value}_{position}_{type_value}"
        hash_obj = hashlib.sha256(unique_str.encode())

        # Generate token with uppercase type name
        return f"[{type_value.upper()}_{hash_obj.hexdigest()[:8]}]"

    def redact(self, text: str, start_pos: int = 0) -> Tuple[str, List[RedactionToken]]:
        """
        Redact sensitive information in the text.

        Args:
            text: The text to redact
            start_pos: Starting position offset (for chunked processing)

        Returns:
            Tuple of (redacted_text, list of tokens)
        """
        if not self._compiled_pattern:
            self._compiled_pattern = re.compile(self.get_pattern())

        tokens = []

        # Finding PII using regex
        matches = list(self._compiled_pattern.finditer(text))

        if not matches:
            return text, tokens

        # Process matches in reverse to maintain position accuracy
        result = text
        for match in reversed(matches):
            original_value = match.group(0)
            match_start = match.start()
            match_end = match.end()

            # Validate the match
            if self.validate(original_value):
                token_id = self.generate_token_id(original_value, start_pos + match_start)
                token = RedactionToken(
                    token_id=token_id,
                    original_value=original_value,
                    redaction_type=self.redaction_type,
                    start_pos=start_pos + match_start,
                    end_pos=start_pos + match_end
                )
                tokens.insert(0, token)

                # Replace with token
                result = result[:match_start] + token_id + result[match_end:]

        return result, tokens


class BaseProvider(ABC):
    """Base class for cloud providers."""

    def __init__(self, client_id: Optional[str] = None,
                 client_secret: Optional[str] = None,
                 **kwargs):
        self.client_id = client_id
        self.client_secret = client_secret
        self.extra_config = kwargs

    @abstractmethod
    def initialize(self):
        """Initialize the provider (sync)."""
        pass

    @abstractmethod
    async def initialize_async(self):
        """Initialize the provider (async)."""
        pass

    @abstractmethod
    def get_secret(self, secret_name: str) -> Dict[str, Any]:
        """Retrieve a secret (sync)."""
        pass

    @abstractmethod
    async def get_secret_async(self, secret_name: str) -> Dict[str, Any]:
        """Retrieve a secret (async)."""
        pass

    @abstractmethod
    def validate_credentials(self) -> bool:
        """Validate the provider credentials."""
        pass


class BaseSecretManager(ABC):
    """Base class for secret management."""

    @abstractmethod
    def get_credentials(self) -> Dict[str, str]:
        """Get credentials from the secret store."""
        pass

    @abstractmethod
    async def get_credentials_async(self) -> Dict[str, str]:
        """Get credentials from the secret store (async)."""
        pass
