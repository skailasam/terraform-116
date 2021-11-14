import json
import logging
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """Log S3 event Key & Bucket
    - event: S3 event
    - bucket: S3 event bucket
    - key: S3 event key
    """
    if event["Records"][0].has_key("s3"):
        s3 = dict()
        s3["key"] = urllib.parse.unquote_plus(
            event["Records"][0]["s3"]["object"]["key"], encoding="utf-8"
        )
        s3["bucket"] = event["Records"][0]["s3"]["bucket"]["name"]
        logger.info("## S3 EVENT\r" + json.dumps(s3))
        return {"statusCode": 200, "body": ""}
    else:
        return {"statusCode": 400, "body": "Missing S3 bucket"}
