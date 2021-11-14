import json
import logging
import os

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """Log SQS event & put event into an object in the S3 bucket
    - event: SQS event
    - s3_bucket: environment variable from Terraform created S3 bucket
    - s3_key: environment variable
    """
    logger.info("## SQS EVENT\r" + json.dumps(event))
    s3 = boto3.client("s3")
    s3_bucket = os.environ["s3_bucket"]
    s3_key = os.environ["s3_key"]
    try:
        s3.put_object(Body=json.dumps(event), Bucket=s3_bucket, Key=s3_key)
    except ClientError as e:
        logger.error(e)
        return {"statusCode": 400, "body": format(e)}
    return {"statusCode": 200, "body": ""}
