# Walkthrough - TurboQuant vLLM Cloud Run Deployment Journey

This document summarizes the attempts, findings, and current status of deploying the TurboQuant-enhanced vLLM framework on GCP Cloud Run with NVIDIA RTX 6000 GPUs.

## Objective
Deploy a high-performance vLLM container on GCP Cloud Run with NVIDIA GPU acceleration to run long-context inference benchmarks (Qwen 72B Int4) and verify TurboQuant's KV cache savings.

## Environment
- **Project:** `grhuang-02`
- **Region:** `us-central1`
- **GPU:** `nvidia-rtx-pro-6000` (RTX 6000 Ada Generation)
- **Machine Specs:** 20 CPUs, 80Gi Memory
- **Target Model:** `Qwen/Qwen2.5-72B-Instruct-GPTQ-Int4`

## Timeline of Attempts and Resolutions

### Phase 1: Initial Setup and Configuration
- **What we did:** Created `Dockerfile` based on Ubuntu 22.04 with Python 3.12, installed vLLM 0.18.0, and cloned TurboQuant. Created helper scripts `entrypoint.sh`, `test_needle.py`, and `benchmark.sh`.
- **The Blocker:** Initial attempts to use `--tq-config` failed because TurboQuant is not a native vLLM command-line plugin but requires explicit Python hook installation before the engine initializes.

### Phase 2: Python Wrapper & AttributeError
- **What we did:** Created `run_tq_vllm.py` to monkey-patch vLLM with `enable_no_alloc` from TurboQuant before running the vLLM API server.
- **The Blocker:** The script failed with `AttributeError: module 'vllm.entrypoints.api_server' has no attribute 'main'`. We discovered that vLLM's API server does not expose a clean `main()` function.
- **Resolution:** Updated the wrapper to use `runpy.run_module('vllm.entrypoints.api_server', run_name='__main__')` to correctly emulate running it as a script.

### Phase 3: Caching Issues & Tag v2
- **What we did:** Rebuilt the image and redeployed.
- **The Blocker:** The logs still showed the old `AttributeError` pointing to line 25 calling `api.main()`, even though the local file was updated. We suspected Cloud Build/Cloud Run cache was serving the old image.
- **Resolution:** Built a new image with an explicit tag `gcr.io/grhuang-02/turboquant-vllm:v2` to break the cache.

### Phase 4: Hugging Face Rate Limits (Current Blocker)
- **What we did:** Deployed using the `v2` image with an extended timeout of 900 seconds.
- **The Blocker:** The deployment failed again with the classic "failed to start and listen on port 8000" error after ~5 minutes.
- **The Discovery:** Deep inspection of the logs revealed that it wasn't a code crash, but **Hugging Face rate limiting**:
  > `requests.exceptions.HTTPError: 429 Client Error: Too Many Requests`
  > `We had to rate limit your IP (2600:1900:0:2d0b::3400).`
  Cloud Run instances sharing egress IPs triggered HF's protection mechanisms, preventing the model from downloading.

## Key Learnings & Best Practices Identified
- **Startup Timeout:** Cloud Run has a hard startup probe timeout of roughly 5 minutes. If a model cannot be fully loaded and the server listening on the port within this window, the instance is killed.
- **Internet Downloads are Risky:** Relying on downloading large models (36GB+) from Hugging Face at container startup is highly prone to failures due to rate limits and network bottlenecks.
- **Cloud Run GPU Doc Recommendations:**
  - Use **Cloud Storage volume mounts** to serve models directly.
  - Use **Direct VPC** for high-speed internal access to Cloud Storage.

## Next Steps (Proposed Plan)
To overcome the rate limit and timeout issues, we are planning to:
1.  Download the model to a local directory (host has 115GB space).
2.  Upload it to the provided bucket `gs://grhuang-02-vertex-ai/models/`.
3.  Deploy Cloud Run with GCS FUSE volume mount to read the model locally.
