import json
import logging
import os

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """Log API request & put the body to SQS
    - event: API Gateway request
    - sqs_url: environment variable from Terraform created SQS queue
    - body: API Gateway request body
    - sqs_response: SQS send message response
    """
    logger.info("## API REQUEST\r" + json.dumps(event))
    sqs = boto3.client("sqs")
    sqs_url = os.environ["sqs_url"]
    if event.has_key("body"):
        try:
            sqs_response = sqs.send_message(
                QueueUrl=sqs_url, MessageBody=(event["body"])
            )
        except ClientError as e:
            logger.error(e)
            return {"statusCode": 400, "body": format(e)}
    else:
        return {"statusCode": 400, "body": "Missing body"}

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(sqs_response),
    }
