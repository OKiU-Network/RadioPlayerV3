# RadioPlayerV3 — server deployment (Linux; includes FFmpeg + tgcalls wheels)
# tgcalls==2.0.0 has manylinux wheels for cp36–cp39 only (no Linux cp310 wheel on PyPI).
FROM python:3.9-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --upgrade pip wheel \
    && pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /app/downloads

CMD ["python", "main.py"]
