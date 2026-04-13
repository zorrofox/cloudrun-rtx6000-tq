#!/bin/bash
set -e

# Default values
MODEL=${MODEL:-"Qwen/Qwen2.5-72B-Instruct-GPTQ-Int4"}
GPU_MEMORY_UTILIZATION=${GPU_MEMORY_UTILIZATION:-0.95}
MAX_MODEL_LEN=${MAX_MODEL_LEN:-1048576}
QUANTIZATION=${QUANTIZATION:-"turboquant"}
TQ_CONFIG=${TQ_CONFIG:-'{"key_bits":3, "value_bits":2}'}

echo "Starting vLLM with model: $MODEL"
echo "Max Model Len: $MAX_MODEL_LEN"
echo "Quantization: $QUANTIZATION"
echo "TQ Config: $TQ_CONFIG"

# Start vLLM API server via TurboQuant wrapper
python3 /app/run_tq_vllm.py \
    --model "$MODEL" \
    --gpu-memory-utilization "$GPU_MEMORY_UTILIZATION" \
    --max-model-len "$MAX_MODEL_LEN" \
    "$@"

