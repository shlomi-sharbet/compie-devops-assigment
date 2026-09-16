import os
import time
import logging
from datetime import datetime, timezone
from typing import Dict, Any

from fastapi import FastAPI, Response, status
from pydantic import BaseModel
import boto3
from botocore.exceptions import ClientError, BotoCoreError

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(name)s]: %(message)s"
)
logger = logging.getLogger("compie-app")

app = FastAPI(
    title="Compie DevOps Service",
    description="Microservice built for Compie DevOps Assignment",
    version="1.0.0"
)

# Configuration from Environment Variables
AWS_REGION = os.getenv("AWS_REGION", os.getenv("AWS_DEFAULT_REGION", "us-east-1"))
DYNAMODB_TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME", "compie-dev-table")
APP_MESSAGE = os.getenv("APP_MESSAGE", "Welcome to Compie DevOps Service")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")

# Initialize DynamoDB client
dynamodb_client = boto3.client("dynamodb", region_name=AWS_REGION)
dynamodb_resource = boto3.resource("dynamodb", region_name=AWS_REGION)


@app.on_event("startup")
async def startup_event():
    logger.info(
        f"Starting application in environment: {ENVIRONMENT}, "
        f"Region: {AWS_REGION}, DynamoDB Table: {DYNAMODB_TABLE_NAME}"
    )


@app.get("/", tags=["General"])
async def root() -> Dict[str, Any]:
    """
    Root endpoint: demonstrates database interaction by reading/writing a visit record,
    and returns service details.
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    db_status = "unreachable"
    visit_count = 0
    db_error = None

    try:
        table = dynamodb_resource.Table(DYNAMODB_TABLE_NAME)
        # Atomically increment a counter in DynamoDB to prove write & read
        response = table.update_item(
            Key={"id": "app_metrics"},
            UpdateExpression="ADD visit_count :inc SET last_visit = :time, app_env = :env",
            ExpressionAttributeValues={
                ":inc": 1,
                ":time": timestamp,
                ":env": ENVIRONMENT
            },
            ReturnValues="ALL_NEW"
        )
        visit_count = int(response.get("Attributes", {}).get("visit_count", 1))
        db_status = "connected"
        logger.info(f"Database write/read successful. Total visits: {visit_count}")
    except (ClientError, BotoCoreError, Exception) as e:
        logger.warning(f"Database interaction in root endpoint failed: {str(e)}")
        db_error = str(e)
        db_status = "degraded"

    return {
        "status": "online",
        "service": "compie-devops-app",
        "version": "1.0.0",
        "environment": ENVIRONMENT,
        "message": APP_MESSAGE,
        "database": {
            "table": DYNAMODB_TABLE_NAME,
            "region": AWS_REGION,
            "status": db_status,
            "total_visits": visit_count,
            "error": db_error
        },
        "timestamp": timestamp
    }


@app.get("/health", tags=["Monitoring"])
async def health_check(response: Response) -> Dict[str, Any]:
    """
    Deep Health Check endpoint.
    Verifies that the application can actively communicate with its required dependencies (DynamoDB).
    Returns HTTP 200 if healthy, or HTTP 503 if dependencies are unreachable.
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    try:
        # Actively probe DynamoDB
        table_desc = dynamodb_client.describe_table(TableName=DYNAMODB_TABLE_NAME)
        table_status = table_desc.get("Table", {}).get("TableStatus", "UNKNOWN")

        if table_status in ["ACTIVE", "UPDATING"]:
            return {
                "status": "healthy",
                "database": {
                    "connected": True,
                    "table_name": DYNAMODB_TABLE_NAME,
                    "table_status": table_status
                },
                "timestamp": timestamp
            }
        else:
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            return {
                "status": "degraded",
                "database": {
                    "connected": True,
                    "table_name": DYNAMODB_TABLE_NAME,
                    "table_status": table_status
                },
                "timestamp": timestamp
            }
    except (ClientError, BotoCoreError, Exception) as e:
        logger.error(f"Health check failed to communicate with DynamoDB: {str(e)}")
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {
            "status": "unhealthy",
            "database": {
                "connected": False,
                "table_name": DYNAMODB_TABLE_NAME,
                "error": str(e)
            },
            "timestamp": timestamp
        }
