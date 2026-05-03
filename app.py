from time import time

from flask import Flask, Response, request
from prometheus_client import Counter, Gauge, CONTENT_TYPE_LATEST, generate_latest

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "flask_request_count",
    "HTTP request count",
    ["method", "endpoint", "http_status"],
)
REQUEST_LATENCY = Gauge(
    "flask_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"],
)

@app.before_request
def before_request():
    request.start_time = time()

@app.after_request
def after_request(response):
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.path,
        http_status=response.status_code,
    ).inc()
    REQUEST_LATENCY.labels(endpoint=request.path).set(time() - request.start_time)
    return response

@app.route("/")
def home():
    return "CI/CD DevOps Pipeline is running!"

@app.route("/health")
def health():
    return {"status": "ok"}

@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
