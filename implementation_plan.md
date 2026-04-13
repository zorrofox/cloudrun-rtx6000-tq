# Implementation Plan - Switch to GCS Mount for TurboQuant vLLM

## Goal
Resolve the Hugging Face rate limit (429) error by downloading the model `Qwen/Qwen2.5-72B-Instruct-GPTQ-Int4` to the provided GCS bucket `grhuang-02-vertex-ai` and mounting it to the Cloud Run service.

## User Review Required
> [!IMPORTANT]
> **Direct VPC Configuration**: To optimize model loading from GCS, Cloud Run recommends using Direct VPC. I need to know the VPC network and subnet to use in project `grhuang-02`. If unknown, I will attempt to deploy without it first or ask you to provide it.

## Open Questions
- Do you have a specific VPC network and subnet you prefer for Direct VPC?
- Do you have a Hugging Face token that I can use to speed up the download on the host machine (to avoid rate limits there)?

## Proposed Changes

### Host Machine (Preparation)
- Create a Python virtual environment in the workspace.
- Install `huggingface_hub` in the venv.
- Download `Qwen/Qwen2.5-72B-Instruct-GPTQ-Int4` to a local directory (workspace has 115GB available).
- Upload the downloaded model to `gs://grhuang-02-vertex-ai/models/Qwen2.5-72B-Instruct-GPTQ-Int4`.

### Cloud Run Deployment
- Update the deployment command to mount the GCS bucket path `models/Qwen2.5-72B-Instruct-GPTQ-Int4` to `/models/Qwen2.5-72B-Instruct-GPTQ-Int4` in the container.
- Update environment variables to point to the local mount path.

## Verification Plan
- Verify file existence in GCS bucket.
- Deploy Cloud Run service and check logs for successful model loading from mount point.
