# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.10.12
FROM python:${PYTHON_VERSION}-slim as base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1
ENV PATH /usr/local/cuda/bin:$C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5\bin
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:$C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.5\lib\x64

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

FROM nvidia/cuda:12.5.0-devel-ubuntu22.04

# Set working directory
WORKDIR /app

# Install necessary packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3-dev python3-venv gcc g++ curl gnupg2 ca-certificates lsb-release \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create and activate a virtual environment named 'env' and install dependencies
COPY requirements.txt /app/
RUN python3 -m venv /app/env && \
    /app/env/bin/pip install -r /app/requirements.txt

# Create a non-privileged user that the app will run under.
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

# Switch to the non-privileged user to run the application.
USER appuser

# Copy the source code into the container.
COPY . .

# Set the working directory to /app/src where main.py is located
WORKDIR /app/src

# Ensure the virtual environment is activated
ENV PATH="/app/env/bin:$PATH"

# Expose the port that the application listens on.
EXPOSE 8000

# Run the application.
CMD ["python3", "main.py"]
