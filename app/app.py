
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Hello from AWS Private EC2"}

@app.get("/health")
def health():
    return {"status": "healthy"}
