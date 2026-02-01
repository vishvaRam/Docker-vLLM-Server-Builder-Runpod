#!/bin/bash

# ----------------------------------------------------------------------------
# 🚀 vLLM v0.15.0 Universal RunPod Entrypoint
# Author: Vishva Murthy
# ----------------------------------------------------------------------------

# 1. Start SSH Service (Background)
echo "--- Starting SSH Service ---"
/usr/sbin/sshd -D -e &

# 2. Check for Mandatory Model Name
if [ -z "$MODEL" ]; then
    echo "⚠️  WARNING: MODEL not set. Defaulting to 'Qwen/Qwen2.5-1.5B-Instruct'"
    MODEL="Qwen/Qwen2.5-1.5B-Instruct"
fi

echo "--- Preparing vLLM Command ---"
echo "Model: $MODEL"

# 3. Initialize Command Array
CMD=("vllm" "serve" "$MODEL")

# 4. Helper Functions
add_param() {
    local flag=$1
    local value=$2
    if [ -n "$value" ]; then
        CMD+=("$flag" "$value")
    fi
}

add_bool() {
    local flag=$1
    local value=$2
    if [[ "$value" =~ ^(true|True|TRUE|1|yes|Yes)$ ]]; then
        CMD+=("$flag")
    fi
}

# ----------------------------------------------------------------------------
# 5. Exact 1:1 Parameter Mapping
# ----------------------------------------------------------------------------

# --- Network & Security (Frontend) ---
add_param "--port"                      "${PORT:-8000}"
add_param "--host"                      "0.0.0.0"
add_param "--api-key"                   "$API_KEY"
add_param "--served-model-name"         "$SERVED_MODEL_NAME"
add_param "--allowed-origins"           "$ALLOWED_ORIGINS" # e.g. "*" or "https://myapp.com"
add_param "--response-role"             "$RESPONSE_ROLE"   # Defaults to "assistant"
add_param "--ssl-keyfile"               "$SSL_KEYFILE"
add_param "--ssl-certfile"              "$SSL_CERTFILE"

# --- Logging & Monitoring ---
add_param "--uvicorn-log-level"         "$UVICORN_LOG_LEVEL" # debug, info, warning, error
add_bool  "--disable-log-requests"      "$DISABLE_LOG_REQUESTS"
add_bool  "--enable-server-load-tracking" "$ENABLE_SERVER_LOAD_TRACKING"
add_bool  "--enable-force-include-usage" "$ENABLE_FORCE_INCLUDE_USAGE" # Great for tracking cost per req

# --- Model Loading & Hardware ---
add_param "--revision"                  "$REVISION"
add_param "--tokenizer"                 "$TOKENIZER"
add_param "--dtype"                     "$DTYPE"
add_param "--max-model-len"             "$MAX_MODEL_LEN"
add_bool  "--trust-remote-code"         "${TRUST_REMOTE_CODE:-true}"
add_param "--load-format"               "$LOAD_FORMAT"
add_param "--seed"                      "$SEED"
add_bool  "--enable-sleep-mode"         "$ENABLE_SLEEP_MODE" # Useful for serverless cold-boots

# --- Quantization & GPU Memory ---
add_param "--quantization"              "$QUANTIZATION"
add_param "--kv-cache-dtype"            "$KV_CACHE_DTYPE"
add_param "--gpu-memory-utilization"    "${GPU_MEMORY_UTILIZATION:-0.90}"
add_param "--swap-space"                "$SWAP_SPACE"      # CPU swap in GiB (default 4)
add_param "--cpu-offload-gb"            "$CPU_OFFLOAD_GB"  # Offload weights to CPU
add_param "--block-size"                "$BLOCK_SIZE"      # 16 or 32 (Performance tuning)

# --- Distributed / Multi-GPU ---
add_param "--tensor-parallel-size"      "${TENSOR_PARALLEL_SIZE:-1}"
add_param "--pipeline-parallel-size"    "${PIPELINE_PARALLEL_SIZE:-1}"
add_param "--distributed-executor-backend" "$DISTRIBUTED_EXECUTOR_BACKEND"
add_param "--worker-cls"                "$WORKER_CLS"      # auto, or specific class

# --- Performance, Caching & Compilation ---
add_param "--attention-backend"         "$ATTENTION_BACKEND"
add_bool  "--enable-prefix-caching"     "$ENABLE_PREFIX_CACHING"
add_bool  "--disable-log-stats"         "$DISABLE_LOG_STATS"
add_param "--compilation-config"        "$COMPILATION_CONFIG" # JSON string for torch.compile
add_bool  "--enforce-eager"             "$ENFORCE_EAGER"
add_param "--device"                    "$DEVICE"

# --- Scheduling & Batching ---
add_param "--max-num-seqs"              "$MAX_NUM_SEQS"
add_param "--max-num-batched-tokens"    "$MAX_NUM_BATCHED_TOKENS"
add_param "--scheduling-policy"         "$SCHEDULING_POLICY" # fcfs or priority
add_bool  "--enable-chunked-prefill"    "$ENABLE_CHUNKED_PREFILL"
add_param "--num-scheduler-steps"       "$NUM_SCHEDULER_STEPS" # Multi-step scheduling (vLLM V1)

# --- Generation & Sampling ---
add_param "--max-logprobs"              "$MAX_LOGPROBS"
add_param "--chat-template"             "$CHAT_TEMPLATE"

# --- LoRA (Adapters) ---
add_bool  "--enable-lora"               "$ENABLE_LORA"
add_param "--max-loras"                 "$MAX_LORAS"
add_param "--max-lora-rank"             "$MAX_LORA_RANK"

# --- Multimodal & RAG (Embeddings) ---
add_bool  "--enable-prompt-embeds"      "$ENABLE_PROMPT_EMBEDS"
add_param "--limit-mm-per-prompt"       "$LIMIT_MM_PER_PROMPT"
add_param "--runner"                    "$RUNNER"

# --- Structured Output & Tool Use ---
add_param "--reasoning-parser"          "$REASONING_PARSER"
add_bool  "--enable-auto-tool-choice"   "$ENABLE_AUTO_TOOL_CHOICE"
add_param "--tool-call-parser"          "$TOOL_CALL_PARSER"

# ----------------------------------------------------------------------------
# 6. Execution
# ----------------------------------------------------------------------------

if [ -n "$EXTRA_ARGS" ]; then
    CMD+=($EXTRA_ARGS)
fi

echo "--- Executing Command ---"
echo "${CMD[@]}"
echo "-------------------------"

exec "${CMD[@]}"