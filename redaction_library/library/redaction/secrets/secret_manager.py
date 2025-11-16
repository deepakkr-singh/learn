"""
Unified Secret Manager

Handles secret fetching with configurable sources:
- env: Environment variables only
- keyvault: Azure Key Vault
- secretsmanager: AWS Secrets Manager

With smart fallback logic.
"""

import os
from typing import Dict, Optional
from .azure_keyvault import AzureKeyVaultManager
from .aws_secrets import AWSSecretManager


class SecretManager:
    """
    Unified Secret Manager

    Manages secret fetching from multiple sources with fallback logic.

    Usage:
        # Default: env only, no fallback
        manager = SecretManager(secret_source="env")

        # Env with Key Vault fallback
        manager = SecretManager(
            secret_source="env",
            fallback_provider="keyvault",
            vault_url="https://..."
        )

        # Always fetch from Key Vault
        manager = SecretManager(
            secret_source="keyvault",
            vault_url="https://..."
        )
    """

    def __init__(self,
                 secret_source: str = "env",
                 fallback_provider: Optional[str] = None,
                 vault_url: Optional[str] = None,
                 region: Optional[str] = None,
                 use_managed_identity: bool = True,
                 client_id: Optional[str] = None,
                 client_secret: Optional[str] = None,
                 tenant_id: Optional[str] = None,
                 aws_access_key_id: Optional[str] = None,
                 aws_secret_access_key: Optional[str] = None):
        """
        Initialize Secret Manager.

        Args:
            secret_source: Primary source ("env", "keyvault", "secretsmanager")
            fallback_provider: Fallback when env is empty ("keyvault", "secretsmanager", None)
            vault_url: Azure Key Vault URL (required for keyvault)
            region: AWS region (required for secretsmanager)
            use_managed_identity: Use DefaultAzureCredential for Azure
            client_id: Azure Service Principal client ID
            client_secret: Azure Service Principal client secret
            tenant_id: Azure tenant ID
            aws_access_key_id: AWS access key ID
            aws_secret_access_key: AWS secret access key
        """
        self.secret_source = secret_source
        self.fallback_provider = fallback_provider

        print(f"[SECRET MANAGER] Initialized")
        print(f"  Primary source: {secret_source}")
        print(f"  Fallback provider: {fallback_provider or 'None'}")

        # Initialize Azure Key Vault if needed
        self.azure_kv = None
        if secret_source == "keyvault" or fallback_provider == "keyvault":
            if not vault_url:
                raise ValueError("vault_url is required when using Key Vault")

            print(f"[SECRET MANAGER] Initializing Azure Key Vault client")
            self.azure_kv = AzureKeyVaultManager(
                vault_url=vault_url,
                client_id=client_id if not use_managed_identity else None,
                client_secret=client_secret if not use_managed_identity else None,
                tenant_id=tenant_id if not use_managed_identity else None
            )

        # Initialize AWS Secrets Manager if needed
        self.aws_sm_region = region
        self.aws_access_key_id = aws_access_key_id
        self.aws_secret_access_key = aws_secret_access_key

        if secret_source == "secretsmanager" or fallback_provider == "secretsmanager":
            if not region:
                raise ValueError("region is required when using AWS Secrets Manager")
            print(f"[SECRET MANAGER] AWS Secrets Manager region: {region}")

    def get_secret(self, secret_name: str, env_var_name: Optional[str] = None) -> Optional[str]:
        """
        Get secret using configured strategy.

        Logic:
        - If secret_source="env": Check env → fallback if not found
        - If secret_source="keyvault": Always fetch from Key Vault, store in env
        - If secret_source="secretsmanager": Always fetch from Secrets Manager, store in env

        Args:
            secret_name: Secret name (e.g., 'azure-client-id' or 'AZURE_CLIENT_ID')
            env_var_name: Override environment variable name

        Returns:
            Secret value or None
        """
        # Determine env var name
        if not env_var_name:
            env_var_name = secret_name.replace('-', '_').replace('/', '_').upper()

        # FLOW 3: secret_source is keyvault - Always fetch and store in env
        if self.secret_source == "keyvault":
            print(f"[SECRET MANAGER] Fetching from Key Vault: {secret_name}")
            secret_value = self.azure_kv.get_secret(secret_name)
            if secret_value:
                os.environ[env_var_name] = secret_value
                print(f"[SECRET MANAGER] ✓ Fetched and stored in env: {env_var_name}")
            return secret_value

        # FLOW 3: secret_source is secretsmanager - Always fetch and store in env
        elif self.secret_source == "secretsmanager":
            print(f"[SECRET MANAGER] Fetching from Secrets Manager: {secret_name}")
            manager = AWSSecretManager(
                secret_name=secret_name,
                region_name=self.aws_sm_region,
                aws_access_key_id=self.aws_access_key_id,
                aws_secret_access_key=self.aws_secret_access_key
            )
            try:
                credentials = manager.get_credentials()
                # Handle JSON secrets
                if isinstance(credentials, dict):
                    if len(credentials) == 1 and 'value' in credentials:
                        secret_value = credentials['value']
                    else:
                        import json
                        secret_value = json.dumps(credentials)
                else:
                    secret_value = str(credentials)

                os.environ[env_var_name] = secret_value
                print(f"[SECRET MANAGER] ✓ Fetched and stored in env: {env_var_name}")
                return secret_value
            except ValueError as e:
                print(f"[SECRET MANAGER] ✗ {e}")
                return None

        # FLOW 1 & 2: secret_source is env
        # Check environment first
        env_value = os.getenv(env_var_name)

        if env_value:
            print(f"[SECRET MANAGER] ✓ Found in environment: {env_var_name}")
            return env_value

        # Not in environment - check fallback
        if self.fallback_provider == "keyvault":
            print(f"[SECRET MANAGER] Not in env, using fallback: Key Vault")
            secret_value = self.azure_kv.get_secret(secret_name)
            if secret_value:
                os.environ[env_var_name] = secret_value
                print(f"[SECRET MANAGER] ✓ Fetched and stored in env: {env_var_name}")
            return secret_value

        elif self.fallback_provider == "secretsmanager":
            print(f"[SECRET MANAGER] Not in env, using fallback: Secrets Manager")
            manager = AWSSecretManager(
                secret_name=secret_name,
                region_name=self.aws_sm_region,
                aws_access_key_id=self.aws_access_key_id,
                aws_secret_access_key=self.aws_secret_access_key
            )
            try:
                credentials = manager.get_credentials()
                if isinstance(credentials, dict):
                    if len(credentials) == 1 and 'value' in credentials:
                        secret_value = credentials['value']
                    else:
                        import json
                        secret_value = json.dumps(credentials)
                else:
                    secret_value = str(credentials)

                os.environ[env_var_name] = secret_value
                print(f"[SECRET MANAGER] ✓ Fetched and stored in env: {env_var_name}")
                return secret_value
            except ValueError as e:
                print(f"[SECRET MANAGER] ✗ {e}")
                return None
        else:
            # No fallback - throw error
            print(f"[SECRET MANAGER] ✗ Not found in environment: {env_var_name}")
            raise ValueError(
                f"Secret '{env_var_name}' not found in environment variables. "
                f"Either set the environment variable or configure a fallback_provider."
            )

    def get_azure_secrets(self) -> Dict[str, Optional[str]]:
        """
        Get all Azure-related secrets.

        Returns:
            Dictionary with keys: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, etc.
        """
        secret_mappings = [
            ('azure-client-id', 'AZURE_CLIENT_ID'),
            ('azure-client-secret', 'AZURE_CLIENT_SECRET'),
            ('azure-tenant-id', 'AZURE_TENANT_ID'),
            ('azure-text-analytics-endpoint', 'AZURE_TEXT_ANALYTICS_ENDPOINT'),
        ]

        secrets = {}
        for secret_name, env_var_name in secret_mappings:
            try:
                value = self.get_secret(secret_name, env_var_name)
                secrets[env_var_name] = value
            except ValueError:
                # Secret not found, skip it
                secrets[env_var_name] = None

        return secrets

    def check_azure_credentials_available(self) -> bool:
        """
        Check if Azure credentials are available.

        Returns:
            True if all required credentials are available
        """
        try:
            secrets = self.get_azure_secrets()
            required = ['AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_TENANT_ID', 'AZURE_TEXT_ANALYTICS_ENDPOINT']
            return all(secrets.get(k) for k in required)
        except ValueError:
            return False
