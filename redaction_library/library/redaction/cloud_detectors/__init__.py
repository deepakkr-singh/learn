"""Cloud-based PII detectors using Azure and AWS AI services."""

from .azure_text_analytics import AzureTextAnalyticsPIIDetector
from .aws_comprehend import AWSComprehendPIIDetector

__all__ = ['AzureTextAnalyticsPIIDetector', 'AWSComprehendPIIDetector']
