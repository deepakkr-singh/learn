"""Azure provider implementation."""
from typing import Dict, Any, Optional
from azure.identity import ClientSecretCredential, DefaultAzureCredential
from ..base import BaseProvider
from ..secrets import AzureKeyVaultManager


class AzureProvider(BaseProvider):
    """Azure cloud provider for credentials and services."""

    def __init__(self,
                 client_id: Optional[str] = None,
                 client_secret: Optional[str] = None,
                 tenant_id: Optional[str] = None,
                 vault_url: Optional[str] = None):
        """
        Initialize Azure provider.

        Args:
            client_id: Azure client ID
            client_secret: Azure client secret
            tenant_id: Azure tenant ID
            vault_url: Azure Key Vault URL (if using Key Vault)
        """
        super().__init__(client_id, client_secret, tenant_id=tenant_id)
        self.tenant_id = tenant_id
        self.vault_url = vault_url
        self._credential = None
        self._key_vault_manager = None
        self._initialized = False

    def initialize(self):
        """Initialize the Azure provider (sync)."""
        if self._initialized:
            return

        # Create credential
        if self.client_id and self.client_secret and self.tenant_id:
            self._credential = ClientSecretCredential(
                tenant_id=self.tenant_id,
                client_id=self.client_id,
                client_secret=self.client_secret
            )
        else:
            # Use DefaultAzureCredential for managed identity or local dev
            self._credential = DefaultAzureCredential()

        # If vault URL is provided, use Key Vault
        if self.vault_url:
            self._key_vault_manager = AzureKeyVaultManager(
                vault_url=self.vault_url,
                client_id=self.client_id,
                client_secret=self.client_secret,
                tenant_id=self.tenant_id
            )
            credentials = self._key_vault_manager.get_credentials()
            self.client_id = credentials.get('client_id', self.client_id)
            self.client_secret = credentials.get('client_secret', self.client_secret)
            self.tenant_id = credentials.get('tenant_id', self.tenant_id)

        self._initialized = True

    async def initialize_async(self):
        """Initialize the Azure provider (async)."""
        if self._initialized:
            return

        # Create credential
        if self.client_id and self.client_secret and self.tenant_id:
            self._credential = ClientSecretCredential(
                tenant_id=self.tenant_id,
                client_id=self.client_id,
                client_secret=self.client_secret
            )
        else:
            # Use DefaultAzureCredential for managed identity or local dev
            self._credential = DefaultAzureCredential()

        # If vault URL is provided, use Key Vault
        if self.vault_url:
            self._key_vault_manager = AzureKeyVaultManager(
                vault_url=self.vault_url,
                client_id=self.client_id,
                client_secret=self.client_secret,
                tenant_id=self.tenant_id
            )
            credentials = await self._key_vault_manager.get_credentials_async()
            self.client_id = credentials.get('client_id', self.client_id)
            self.client_secret = credentials.get('client_secret', self.client_secret)
            self.tenant_id = credentials.get('tenant_id', self.tenant_id)

        self._initialized = True

    def get_secret(self, secret_name: str) -> Dict[str, Any]:
        """
        Retrieve a secret from Azure Key Vault (sync).

        Args:
            secret_name: Name of the secret

        Returns:
            Dictionary containing the secret data
        """
        if not self._initialized:
            self.initialize()

        if not self.vault_url:
            raise ValueError("vault_url must be provided to retrieve secrets")

        key_vault_manager = AzureKeyVaultManager(
            vault_url=self.vault_url,
            client_id=self.client_id,
            client_secret=self.client_secret,
            tenant_id=self.tenant_id
        )
        secret_value = key_vault_manager.get_secret(secret_name)
        return {'value': secret_value} if secret_value else {}

    async def get_secret_async(self, secret_name: str) -> Dict[str, Any]:
        """
        Retrieve a secret from Azure Key Vault (async).

        Args:
            secret_name: Name of the secret

        Returns:
            Dictionary containing the secret data
        """
        if not self._initialized:
            await self.initialize_async()

        if not self.vault_url:
            raise ValueError("vault_url must be provided to retrieve secrets")

        key_vault_manager = AzureKeyVaultManager(
            vault_url=self.vault_url,
            client_id=self.client_id,
            client_secret=self.client_secret,
            tenant_id=self.tenant_id
        )
        secret_value = await key_vault_manager.get_secret_async(secret_name)
        return {'value': secret_value} if secret_value else {}

    def validate_credentials(self) -> bool:
        """
        Validate Azure credentials.

        Returns:
            True if credentials are valid
        """
        try:
            if not self._credential:
                self.initialize()

            # Try to get a token
            token = self._credential.get_token("https://management.azure.com/.default")
            return token is not None
        except Exception:
            return False

    def get_credential(self):
        """
        Get the Azure credential object.

        Returns:
            Azure credential
        """
        if not self._initialized:
            self.initialize()

        return self._credential

    async def get_credential_async(self):
        """
        Get the Azure credential object (async).

        Returns:
            Azure credential
        """
        if not self._initialized:
            await self.initialize_async()

        return self._credential
