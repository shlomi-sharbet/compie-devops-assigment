import os
from fastapi.testclient import TestClient

# Mock AWS region and table name for local testing
os.environ["AWS_REGION"] = "eu-north-1"
os.environ["AWS_DEFAULT_REGION"] = "eu-north-1"
os.environ["DYNAMODB_TABLE_NAME"] = "compie-test-table"
os.environ["APP_MESSAGE"] = "Test Environment Message"
os.environ["ENVIRONMENT"] = "test"

from app.main import app

client = TestClient(app)


def test_root_endpoint_structure():
    """Verify that the root endpoint returns expected metadata keys."""
    response = client.get("/")
    # Even if DynamoDB is mocked or degraded in test environment, root returns 200
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "compie-devops-app"
    assert "version" in data
    assert "database" in data
    assert data["database"]["table"] == "compie-test-table"


def test_health_endpoint_structure():
    """Verify that the health check endpoint responds with JSON."""
    response = client.get("/health")
    # In test environment without active AWS credentials, health returns 503 (unhealthy) or 200
    assert response.status_code in [200, 503]
    data = response.json()
    assert "status" in data
    assert "database" in data
