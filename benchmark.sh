#!/bin/bash
# benchmark.sh

MODEL_URL=${MODEL_URL:-"http://localhost:8000"}

echo "Waiting for vLLM server to be ready at $MODEL_URL..."
while ! curl -s $MODEL_URL/health > /dev/null; do
    sleep 5
    echo -n "."
done
echo "\nServer is ready!"

echo "============================================================"
echo "Starting TurboQuant x RTX 6000 Benchmark"
echo "============================================================"

# Phase 2: Accuracy Tests (Running first to ensure it works before pushing limits)
echo -e "\n>>> Running Phase 2: Needle In A Haystack Accuracy Tests <<<"
python3 /app/test_needle.py --model_url $MODEL_URL --context_len 100000 --test_type all
python3 /app/test_needle.py --model_url $MODEL_URL --context_len 500000 --test_type all
# python3 /app/test_needle.py --model_url $MODEL_URL --context_len 1000000 --test_type all # Uncomment for 1M test

# Phase 3: Performance Tests (TTFT & Decode Speed)
echo -e "\n>>> Running Phase 3: Performance Tests <<<"

test_performance() {
    local len=$1
    echo "Testing with context length: $len"
    
    # Prepare a dummy prompt of desired length
    # We use python to generate a large json payload directly
    python3 -c "
import requests
import time
import json

prompt = 'Once upon a time ' * ($len // 4)
payload = {
    'prompt': prompt,
    'max_tokens': 50,
    'temperature': 0.0
}

start_time = time.time()
try:
    response = requests.post('$MODEL_URL/generate', json=payload)
    end_time = time.time()
    
    if response.status_code == 200:
        result = response.json()
        duration = end_time - start_time
        print(f'Success! Total time: {duration:.2f}s')
        print(f'Response snippet: {result[\"text\"][0][:50]}...')
    else:
        print(f'Failed with status code: {response.status_code}')
except Exception as e:
    print(f'Error: {e}')
"
}

test_performance 100000
test_performance 500000
# test_performance 1000000 # Uncomment for 1M test

echo "============================================================"
echo "Benchmark Completed"
echo "============================================================"
