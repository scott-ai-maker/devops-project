"""
FastAPI application for DevOps demonstration.
Includes health checks, metrics, and structured logging.
"""
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import logging
import time
import os
from datetime import datetime

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# App metadata
app = FastAPI(
    title="DevOps Demo API",
    description="A production-ready FastAPI demo for Azure/K8s deployment",
    version="1.0.0"
)

# Request/response models
class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str
    environment: str

class MessageRequest(BaseModel):
    message: str

class MessageResponse(BaseModel):
    received: str
    processed_at: str
    echo: str

# Application state for metrics
app_start_time = time.time()
request_count = 0

@app.on_event("startup")
async def startup_event():
    """Log application startup"""
    logger.info("🚀 Application starting up")
    logger.info(f"Environment: {os.getenv('ENVIRONMENT', 'development')}")

@app.on_event("shutdown")
async def shutdown_event():
    """Log application shutdown"""
    logger.info("🛑 Application shutting down")

@app.get("/")
async def root():
    """Root endpoint with basic info"""
    return {
        "service": "DevOps Demo API",
        "status": "running",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint for Kubernetes probes.
    Returns 200 if service is healthy.
    """
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0",
        environment=os.getenv("ENVIRONMENT", "development")
    )

@app.get("/ready")
async def readiness_check():
    """
    Readiness check for Kubernetes.
    Can add database/dependency checks here.
    """
    # In production, check database connectivity, external services, etc.
    return {"status": "ready", "timestamp": datetime.utcnow().isoformat()}

@app.get("/metrics")
async def metrics():
    """
    Basic metrics endpoint (Prometheus-compatible format can be added).
    Shows uptime and request count.
    """
    uptime = time.time() - app_start_time
    return {
        "uptime_seconds": round(uptime, 2),
        "requests_total": request_count,
        "status": "healthy"
    }

@app.post("/api/message", response_model=MessageResponse)
async def process_message(request: MessageRequest):
    """
    Example API endpoint that processes a message.
    Demonstrates request validation and logging.
    """
    global request_count
    request_count += 1
    
    logger.info(f"Processing message: {request.message[:50]}...")
    
    return MessageResponse(
        received=request.message,
        processed_at=datetime.utcnow().isoformat(),
        echo=f"Processed: {request.message}"
    )

@app.get("/api/info")
async def get_info():
    """
    Returns environment information (useful for debugging deployments).
    """
    return {
        "hostname": os.getenv("HOSTNAME", "unknown"),
        "environment": os.getenv("ENVIRONMENT", "development"),
        "azure_region": os.getenv("AZURE_REGION", "not-set"),
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
