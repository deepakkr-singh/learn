"""AWS provider implementation."""
from typing import Dict, Any, Optional
import boto3
import aioboto3
from botocore.exceptions import ClientError
from ..base import BaseProvider
from ..secrets import AWSSecretManager


class AWSProvider(BaseProvider):
    """AWS cloud provider for credentials and services."""

    def __init__(self,
                 client_id: Optional[str] = None,
                 client_secret: Optional[str] = None,
                 region: str = 'us-east-1',
                 secret_name: Optional[str] = None):
        """
        Initialize AWS provider.

        Args:
            client_id: AWS access key ID
            client_secret: AWS secret access key
            region: AWS region
            secret_name: Name of secret in AWS Secrets Manager (if using secrets manager)
        """
        super().__init__(client_id, client_secret, region=region)
        self.region = region
        self.secret_name = secret_name
        self._secret_manager = None
        self._initialized = False

    def initialize(self):
        """Initialize the AWS provider (sync)."""
        if self._initialized:
            return

        # If secret name is provided, use Secrets Manager
        if self.secret_name:
            self._secret_manager = AWSSecretManager(
                secret_name=self.secret_name,
                region_name=self.region,
                aws_access_key_id=self.client_id,
                aws_secret_access_key=self.client_secret
            )
            credentials = self._secret_manager.get_credentials()
            self.client_id = credentials.get('aws_access_key_id', self.client_id)
            self.client_secret = credentials.get('aws_secret_access_key', self.client_secret)

        self._initialized = True

    async def initialize_async(self):
        """Initialize the AWS provider (async)."""
        if self._initialized:
            return

        # If secret name is provided, use Secrets Manager
        if self.secret_name:
            self._secret_manager = AWSSecretManager(
                secret_name=self.secret_name,
                region_name=self.region,
                aws_access_key_id=self.client_id,
                aws_secret_access_key=self.client_secret
            )
            credentials = await self._secret_manager.get_credentials_async()
            self.client_id = credentials.get('aws_access_key_id', self.client_id)
            self.client_secret = credentials.get('aws_secret_access_key', self.client_secret)

        self._initialized = True

    def get_secret(self, secret_name: str) -> Dict[str, Any]:
        """
        Retrieve a secret from AWS Secrets Manager (sync).

        Args:
            secret_name: Name of the secret

        Returns:
            Dictionary containing the secret data
        """
        if not self._initialized:
            self.initialize()

        secret_manager = AWSSecretManager(
            secret_name=secret_name,
            region_name=self.region,
            aws_access_key_id=self.client_id,
            aws_secret_access_key=self.client_secret
        )
        return secret_manager.get_credentials()

    async def get_secret_async(self, secret_name: str) -> Dict[str, Any]:
        """
        Retrieve a secret from AWS Secrets Manager (async).

        Args:
            secret_name: Name of the secret

        Returns:
            Dictionary containing the secret data
        """
        if not self._initialized:
            await self.initialize_async()

        secret_manager = AWSSecretManager(
            secret_name=secret_name,
            region_name=self.region,
            aws_access_key_id=self.client_id,
            aws_secret_access_key=self.client_secret
        )
        return await secret_manager.get_credentials_async()

    def validate_credentials(self) -> bool:
        """
        Validate AWS credentials.

        Returns:
            True if credentials are valid
        """
        try:
            if self.client_id and self.client_secret:
                client = boto3.client(
                    'sts',
                    region_name=self.region,
                    aws_access_key_id=self.client_id,
                    aws_secret_access_key=self.client_secret
                )
            else:
                client = boto3.client('sts', region_name=self.region)

            # Try to get caller identity
            client.get_caller_identity()
            return True
        except ClientError:
            return False

    def get_client(self, service_name: str):
        """
        Get a boto3 client for a specific AWS service.

        Args:
            service_name: Name of the AWS service (e.g., 's3', 'dynamodb')

        Returns:
            Boto3 client
        """
        if not self._initialized:
            self.initialize()

        if self.client_id and self.client_secret:
            return boto3.client(
                service_name,
                region_name=self.region,
                aws_access_key_id=self.client_id,
                aws_secret_access_key=self.client_secret
            )
        else:
            return boto3.client(service_name, region_name=self.region)

    async def get_client_async(self, service_name: str):
        """
        Get an aioboto3 client for a specific AWS service (async).

        Args:
            service_name: Name of the AWS service

        Returns:
            Async context manager for aioboto3 client
        """
        if not self._initialized:
            await self.initialize_async()

        session = aioboto3.Session()

        if self.client_id and self.client_secret:
            return session.client(
                service_name,
                region_name=self.region,
                aws_access_key_id=self.client_id,
                aws_secret_access_key=self.client_secret
            )
        else:
            return session.client(service_name, region_name=self.region)
