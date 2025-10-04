# syntax=docker/dockerfile:1.6

FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN python -m pip install --upgrade pip setuptools wheel

RUN if [ -f "requirements.txt" ]; then pip install -r requirements.txt; fi
RUN if [ -f "requirements-dev.txt" ]; then pip install -r requirements-dev.txt; fi

ENV DJANGO_LOG_DIR=/app/logs

RUN mkdir -p "$DJANGO_LOG_DIR"

EXPOSE 8000

CMD ["bash", "scripts/entrypoint.sh"]
