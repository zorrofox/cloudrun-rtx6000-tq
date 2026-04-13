import sys
import os
import json
import runpy
from turboquant.vllm_attn_backend import enable_no_alloc

# Read config from environment
tq_config_str = os.environ.get("TQ_CONFIG", '{"key_bits":3, "value_bits":2}')
try:
    tq_config = json.loads(tq_config_str)
except Exception as e:
    print(f"Error parsing TQ_CONFIG: {e}")
    tq_config = {"key_bits": 3, "value_bits": 2}

key_bits = tq_config.get("key_bits", 3)
value_bits = tq_config.get("value_bits", 2)

print(f"[TurboQuant Wrapper] Enabling TQ with key_bits={key_bits}, value_bits={value_bits}")
enable_no_alloc(key_bits=key_bits, value_bits=value_bits)

# Set sys.argv to pass arguments to api_server
sys.argv = ['vllm.entrypoints.api_server'] + sys.argv[1:]

print(f"[TurboQuant Wrapper] Starting vLLM api_server with args: {sys.argv}")
runpy.run_module('vllm.entrypoints.api_server', run_name='__main__')
