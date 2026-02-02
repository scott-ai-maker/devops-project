# Simple test file for FastAPI app
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_read_root():
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    assert "service" in response.json()


def test_health_check():
    """Test health endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_readiness_check():
    """Test readiness endpoint"""
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_metrics():
    """Test metrics endpoint"""
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "uptime_seconds" in response.json()


def test_process_message():
    """Test message processing endpoint"""
    response = client.post(
        "/api/message",
        json={"message": "Test message"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["received"] == "Test message"
    assert "processed_at" in data


def test_get_info():
    """Test info endpoint"""
    response = client.get("/api/info")
    assert response.status_code == 200
    assert "version" in response.json()
