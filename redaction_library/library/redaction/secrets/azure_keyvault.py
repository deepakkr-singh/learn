"""Azure Key Vault integration."""
from typing import Dict, Optional
from azure.identity import ClientSecretCredential, DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import ResourceNotFoundError, HttpResponseError
import aiohttp


class AzureKeyVaultManager:
    """Manage secrets from Azure Key Vault."""

    def __init__(self,
                 vault_url: str,
                 client_id: Optional[str] = None,
                 client_secret: Optional[str] = None,
                 tenant_id: Optional[str] = None):
        """
        Initialize Azure Key Vault Manager.

        Args:
            vault_url: Azure Key Vault URL (e.g., https://your-vault.vault.azure.net/)
            client_id: Azure client ID (optional, uses DefaultAzureCredential if not provided)
            client_secret: Azure client secret (optional)
            tenant_id: Azure tenant ID (optional)
        """
        self.vault_url = vault_url
        self.client_id = client_id
        self.client_secret = client_secret
        self.tenant_id = tenant_id

        # Initialize credential
        if client_id and client_secret and tenant_id:
            self.credential = ClientSecretCredential(
                tenant_id=tenant_id,
                client_id=client_id,
                client_secret=client_secret
            )
        else:
            # Use DefaultAzureCredential for managed identity or local dev
            self.credential = DefaultAzureCredential()

        # Initialize sync client
        self._client = None

    def _get_client(self) -> SecretClient:
        """Get or create SecretClient."""
        if self._client is None:
            self._client = SecretClient(
                vault_url=self.vault_url,
                credential=self.credential
            )
        return self._client

    def get_credentials(self) -> Dict[str, str]:
        """
        Get credentials from Azure Key Vault (sync).

        Returns:
            Dictionary containing credentials

        Raises:
            ResourceNotFoundError: If secret not found
            HttpResponseError: If unable to retrieve the secret
        """
        try:
            client = self._get_client()

            # Retrieve individual secrets
            credentials = {}

            # Define the secret names to retrieve
            secret_names = [
                'client-id',
                'client-secret',
                'tenant-id',
                'aws-client-id',
                'aws-client-secret',
                'aws-region'
            ]

            for secret_name in secret_names:
                try:
                    secret = client.get_secret(secret_name)
                    # Convert hyphenated names to underscored keys
                    key = secret_name.replace('-', '_')
                    credentials[key] = secret.value
                except ResourceNotFoundError:
                    # Secret doesn't exist, skip it
                    credentials[secret_name.replace('-', '_')] = ''

            return credentials

        except HttpResponseError as e:
            raise ValueError(f"Error retrieving secrets from Azure Key Vault: {e}")

    async def get_credentials_async(self) -> Dict[str, str]:
        """
        Get credentials from Azure Key Vault (async).

        Note: Azure SDK uses sync I/O. For true async, we'd need to use REST API.
        This is a wrapper that runs sync code in async context.

        Returns:
            Dictionary containing credentials
        """
        # Azure SDK doesn't have full async support for KeyVault yet
        # For production, consider using aiohttp with Azure REST API
        # For now, we'll use the sync version
        return self.get_credentials()

    async def get_credentials_async_rest(self) -> Dict[str, str]:
        """
        Get credentials using Azure REST API (true async).

        Returns:
            Dictionary containing credentials
        """
        # Get access token
        token = self.credential.get_token("https://vault.azure.net/.default")

        headers = {
            'Authorization': f'Bearer {token.token}',
            'Content-Type': 'application/json'
        }

        secret_names = [
            'client-id',
            'client-secret',
            'tenant-id',
            'aws-client-id',
            'aws-client-secret',
            'aws-region'
        ]

        credentials = {}

        async with aiohttp.ClientSession() as session:
            for secret_name in secret_names:
                url = f"{self.vault_url}/secrets/{secret_name}?api-version=7.4"
                try:
                    async with session.get(url, headers=headers) as response:
                        if response.status == 200:
                            data = await response.json()
                            key = secret_name.replace('-', '_')
                            credentials[key] = data.get('value', '')
                        else:
                            credentials[secret_name.replace('-', '_')] = ''
                except Exception:
                    credentials[secret_name.replace('-', '_')] = ''

        return credentials

    def set_secret(self, secret_name: str, secret_value: str) -> bool:
        """
        Set a secret in Azure Key Vault.

        Args:
            secret_name: Name of the secret
            secret_value: Value of the secret

        Returns:
            True if successful
        """
        try:
            client = self._get_client()
            client.set_secret(secret_name, secret_value)
            return True
        except HttpResponseError:
            raise

    def get_secret(self, secret_name: str) -> Optional[str]:
        """
        Get a specific secret by name.

        Args:
            secret_name: Name of the secret

        Returns:
            Secret value or None if not found
        """
        try:
            client = self._get_client()
            secret = client.get_secret(secret_name)
            return secret.value
        except ResourceNotFoundError:
            return None

    async def get_secret_async(self, secret_name: str) -> Optional[str]:
        """
        Get a specific secret by name (async using REST API).

        Args:
            secret_name: Name of the secret

        Returns:
            Secret value or None if not found
        """
        token = self.credential.get_token("https://vault.azure.net/.default")

        headers = {
            'Authorization': f'Bearer {token.token}',
            'Content-Type': 'application/json'
        }

        url = f"{self.vault_url}/secrets/{secret_name}?api-version=7.4"

        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, headers=headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get('value')
                    else:
                        return None
        except Exception:
            return None

    def delete_secret(self, secret_name: str) -> bool:
        """
        Delete a secret from Azure Key Vault.

        Args:
            secret_name: Name of the secret to delete

        Returns:
            True if successful
        """
        try:
            client = self._get_client()
            client.begin_delete_secret(secret_name).wait()
            return True
        except ResourceNotFoundError:
            return False
