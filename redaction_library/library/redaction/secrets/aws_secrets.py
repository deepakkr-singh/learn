"""AWS Secrets Manager integration."""
import json
from typing import Dict, Optional
import boto3
from botocore.exceptions import ClientError
import aioboto3
from ..base import BaseSecretManager


class AWSSecretManager(BaseSecretManager):
    """Manage secrets from AWS Secrets Manager."""

    def __init__(self,
                 secret_name: str,
                 region_name: str = 'us-east-1',
                 aws_access_key_id: Optional[str] = None,
                 aws_secret_access_key: Optional[str] = None):
        """
        Initialize AWS Secrets Manager.

        Args:
            secret_name: Name of the secret in AWS Secrets Manager
            region_name: AWS region
            aws_access_key_id: AWS access key ID (optional, uses boto3 defaults if not provided)
            aws_secret_access_key: AWS secret access key (optional)
        """
        self.secret_name = secret_name
        self.region_name = region_name
        self.aws_access_key_id = aws_access_key_id
        self.aws_secret_access_key = aws_secret_access_key

        # Initialize sync client
        self._client = None
        self._session = None

    def _get_client(self):
        """Get or create boto3 client."""
        if self._client is None:
            if self.aws_access_key_id and self.aws_secret_access_key:
                self._client = boto3.client(
                    'secretsmanager',
                    region_name=self.region_name,
                    aws_access_key_id=self.aws_access_key_id,
                    aws_secret_access_key=self.aws_secret_access_key
                )
            else:
                self._client = boto3.client(
                    'secretsmanager',
                    region_name=self.region_name
                )
        return self._client

    def get_credentials(self) -> Dict[str, str]:
        """
        Get credentials from AWS Secrets Manager (sync).

        Returns:
            Dictionary containing credentials

        Raises:
            ClientError: If unable to retrieve the secret
        """
        try:
            client = self._get_client()
            response = client.get_secret_value(SecretId=self.secret_name)

            if 'SecretString' in response:
                secret = json.loads(response['SecretString'])
                return secret
            else:
                raise ValueError("Secret is binary, not JSON string")

        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'ResourceNotFoundException':
                raise ValueError(f"Secret {self.secret_name} not found")
            elif error_code == 'InvalidRequestException':
                raise ValueError(f"Invalid request for secret {self.secret_name}")
            elif error_code == 'InvalidParameterException':
                raise ValueError(f"Invalid parameter for secret {self.secret_name}")
            elif error_code == 'DecryptionFailure':
                raise ValueError(f"Cannot decrypt secret {self.secret_name}")
            elif error_code == 'InternalServiceError':
                raise ValueError(f"AWS service error retrieving {self.secret_name}")
            else:
                raise

    async def get_credentials_async(self) -> Dict[str, str]:
        """
        Get credentials from AWS Secrets Manager (async).

        Returns:
            Dictionary containing credentials

        Raises:
            ClientError: If unable to retrieve the secret
        """
        session = aioboto3.Session()

        try:
            async with session.client(
                'secretsmanager',
                region_name=self.region_name,
                aws_access_key_id=self.aws_access_key_id,
                aws_secret_access_key=self.aws_secret_access_key
            ) as client:
                response = await client.get_secret_value(SecretId=self.secret_name)

                if 'SecretString' in response:
                    secret = json.loads(response['SecretString'])
                    return secret
                else:
                    raise ValueError("Secret is binary, not JSON string")

        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'ResourceNotFoundException':
                raise ValueError(f"Secret {self.secret_name} not found")
            elif error_code == 'InvalidRequestException':
                raise ValueError(f"Invalid request for secret {self.secret_name}")
            elif error_code == 'InvalidParameterException':
                raise ValueError(f"Invalid parameter for secret {self.secret_name}")
            elif error_code == 'DecryptionFailure':
                raise ValueError(f"Cannot decrypt secret {self.secret_name}")
            elif error_code == 'InternalServiceError':
                raise ValueError(f"AWS service error retrieving {self.secret_name}")
            else:
                raise

    def create_secret(self, secret_data: Dict[str, str]) -> bool:
        """
        Create a new secret in AWS Secrets Manager.

        Args:
            secret_data: Dictionary of secret key-value pairs

        Returns:
            True if successful

        Raises:
            ClientError: If unable to create the secret
        """
        try:
            client = self._get_client()
            client.create_secret(
                Name=self.secret_name,
                SecretString=json.dumps(secret_data)
            )
            return True
        except ClientError as e:
            if e.response['Error']['Code'] == 'ResourceExistsException':
                # Secret already exists, update it instead
                return self.update_secret(secret_data)
            else:
                raise

    def update_secret(self, secret_data: Dict[str, str]) -> bool:
        """
        Update an existing secret in AWS Secrets Manager.

        Args:
            secret_data: Dictionary of secret key-value pairs

        Returns:
            True if successful
        """
        try:
            client = self._get_client()
            client.update_secret(
                SecretId=self.secret_name,
                SecretString=json.dumps(secret_data)
            )
            return True
        except ClientError:
            raise
