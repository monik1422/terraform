import json
import os

import boto3
import pymysql  # vendored into this directory at build time (see README)

_secrets = boto3.client("secretsmanager")


def _get_credentials(secret_arn):
    """Fetch the RDS-managed master secret via the Secrets Manager VPC endpoint.

    The RDS-managed secret is a JSON document of the form:
        {"username": "...", "password": "..."}
    """
    resp = _secrets.get_secret_value(SecretId=secret_arn)
    return json.loads(resp["SecretString"])


def handler(event, context):
    creds = _get_credentials(os.environ["DB_SECRET_ARN"])

    conn = pymysql.connect(
        host=os.environ["DB_HOST"],
        user=creds["username"],
        password=creds["password"],
        database=os.environ["DB_NAME"],
        port=int(os.environ.get("DB_PORT", "3306")),
        connect_timeout=5,
    )

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT VERSION();")
            (version,) = cur.fetchone()
    finally:
        conn.close()

    return {
        "statusCode": 200,
        "body": json.dumps({"connected": True, "mysql_version": version}),
    }
