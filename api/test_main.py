import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock
from main import app, r

client = TestClient(app)

@pytest.fixture(autouse=True)
def mock_redis(monkeypatch):
    mock = MagicMock()
    monkeypatch.setattr("main.r", mock)
    return mock

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_create_job(mock_redis):
    response = client.post("/jobs")
    assert response.status_code == 200
    assert "job_id" in response.json()
    assert mock_redis.lpush.called

def test_get_job_found(mock_redis):
    mock_redis.hget.return_value = b"completed"
    response = client.get("/jobs/12345")
    assert response.status_code == 200
    assert response.json() == {"job_id": "12345", "status": "completed"}
    mock_redis.hget.assert_called_with("job:12345", "status")

def test_get_job_not_found(mock_redis):
    mock_redis.hget.return_value = None
    response = client.get("/jobs/12345")
    assert response.status_code == 200
    assert response.json() == {"error": "not found"}
