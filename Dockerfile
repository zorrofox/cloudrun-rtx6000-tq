# Use NVIDIA CUDA 12.8 devel image as base
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies and add deadsnakes PPA for Python 3.12
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    git \
    wget \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Set python3.12 as default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install pip for Python 3.12
RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# Upgrade pip
RUN python -m pip install --upgrade pip

# Install vLLM (User specified v0.18.0)
RUN pip install vllm==0.18.0

# Install Triton (Required by TurboQuant)
RUN pip install triton

# Clone and install TurboQuant from assumed repo
RUN git clone https://github.com/0xSero/turboquant.git /opt/turboquant \
    && cd /opt/turboquant && pip install .

# Install additional dependencies for testing
RUN pip install transformers datasets pandas scipy rouge_score requests

# Copy test scripts
COPY test_needle.py /app/test_needle.py
COPY benchmark.sh /app/benchmark.sh
COPY entrypoint.sh /app/entrypoint.sh
COPY run_tq_vllm.py /app/run_tq_vllm.py


RUN chmod +x /app/benchmark.sh /app/entrypoint.sh

WORKDIR /app

# Expose vLLM port
EXPOSE 8000

# Default entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
