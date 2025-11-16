"""
Redaction Library - A powerful library for redacting sensitive information.

Supports multiple cloud providers (AWS, Azure) with sync and async implementations.
"""

from .service import RedactionService
from .base import (
    BaseRedactor,
    BaseProvider,
    BaseSecretManager,
    RedactionResult,
    RedactionToken,
    RedactionType
)
from .redactors import (
    EmailRedactor,
    PhoneRedactor,
    SSNRedactor,
    CreditCardRedactor,
    BankAccountRedactor,
    IPAddressRedactor,
    PassportRedactor
)
from .providers import AWSProvider, AzureProvider
from .secrets import SecretManager, AWSSecretManager, AzureKeyVaultManager
from .utils import TextChunker, ParallelProcessor

__version__ = "1.0.0"

__all__ = [
    # Main service
    'RedactionService',
    # Base classes
    'BaseRedactor',
    'BaseProvider',
    'BaseSecretManager',
    'RedactionResult',
    'RedactionToken',
    'RedactionType',
    # Redactors
    'EmailRedactor',
    'PhoneRedactor',
    'SSNRedactor',
    'CreditCardRedactor',
    'BankAccountRedactor',
    'IPAddressRedactor',
    'PassportRedactor',
    # Providers
    'AWSProvider',
    'AzureProvider',
    # Secret managers
    'SecretManager',
    'AWSSecretManager',
    'AzureKeyVaultManager',
    # Utilities
    'TextChunker',
    'ParallelProcessor',
]
