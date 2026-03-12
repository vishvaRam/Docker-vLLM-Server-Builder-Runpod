#!/bin/bash
set -euo pipefail

# ----------------------------------------------------------------------------
# 🚀 vLLM Universal RunPod Entrypoint
# ----------------------------------------------------------------------------

echo "--- Starting SSH Service ---"
/usr/sbin/sshd -D -e &

# 1. Check for mandatory model name
if [ -z "${MODEL:-}" ]; then
    echo "⚠️  WARNING: MODEL not set. Defaulting to 'Qwen/Qwen2.5-1.5B-Instruct'"
    MODEL="Qwen/Qwen2.5-1.5B-Instruct"
fi

echo "--- Preparing vLLM Command ---"
echo "Model: $MODEL"

# 2. Initialize command array
CMD=("vllm" "serve" "$MODEL")

# ----------------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------------

add_param() {
    local flag="$1"
    local value="${2:-}"
    if [ -n "$value" ]; then
        CMD+=("$flag" "$value")
    fi
}

add_bool() {
    local flag="$1"
    local value="${2:-}"
    case "${value,,}" in
        true|1|yes)
            CMD+=("$flag")
            ;;
    esac
}

add_toggle() {
    local enable_flag="$1"
    local disable_flag="$2"
    local value="${3:-}"

    case "${value,,}" in
        true|1|yes)
            CMD+=("$enable_flag")
            ;;
        false|0|no)
            CMD+=("$disable_flag")
            ;;
        *)
            ;;
    esac
}

print_cmd() {
    printf '%q ' "${CMD[@]}"
    echo
}

# ----------------------------------------------------------------------------
# 3. Exact 1:1 Parameter Mapping
# ----------------------------------------------------------------------------

# --- Network & Security (Frontend) ---
add_param "--port"                          "${PORT:-8000}"
add_param "--host"                          "0.0.0.0"
add_param "--api-key"                       "${API_KEY:-}"
add_param "--served-model-name"             "${SERVED_MODEL_NAME:-}"
add_param "--allowed-origins"               "${ALLOWED_ORIGINS:-}"
add_param "--response-role"                 "${RESPONSE_ROLE:-}"
add_param "--ssl-keyfile"                   "${SSL_KEYFILE:-}"
add_param "--ssl-certfile"                  "${SSL_CERTFILE:-}"

# --- Logging & Monitoring ---
add_param "--uvicorn-log-level"             "${UVICORN_LOG_LEVEL:-}"
add_bool  "--disable-log-requests"          "${DISABLE_LOG_REQUESTS:-}"
add_bool  "--enable-server-load-tracking"   "${ENABLE_SERVER_LOAD_TRACKING:-}"
add_bool  "--enable-force-include-usage"    "${ENABLE_FORCE_INCLUDE_USAGE:-}"

# --- Model Loading & Hardware ---
add_param "--revision"                      "${REVISION:-}"
add_param "--tokenizer"                     "${TOKENIZER:-}"
add_param "--tokenizer-mode"                "${TOKENIZER_MODE:-}"
add_param "--dtype"                         "${DTYPE:-}"
add_param "--max-model-len"                 "${MAX_MODEL_LEN:-}"
add_bool  "--trust-remote-code"             "${TRUST_REMOTE_CODE:-true}"
add_param "--load-format"                   "${LOAD_FORMAT:-}"
add_param "--seed"                          "${SEED:-}"
add_bool  "--enable-sleep-mode"             "${ENABLE_SLEEP_MODE:-}"

# --- Quantization / Speculative / Memory ---
add_param "--quantization"                  "${QUANTIZATION:-}"
add_param "--kv-cache-dtype"                "${KV_CACHE_DTYPE:-}"
add_param "--gpu-memory-utilization"        "${GPU_MEMORY_UTILIZATION:-0.90}"
add_param "--swap-space"                    "${SWAP_SPACE:-}"
add_param "--cpu-offload-gb"                "${CPU_OFFLOAD_GB:-}"
add_param "--block-size"                    "${BLOCK_SIZE:-}"
add_param "--speculative-config"            "${SPECULATIVE_CONFIG:-}"

# --- Distributed / Multi-GPU ---
add_param "--tensor-parallel-size"          "${TENSOR_PARALLEL_SIZE:-1}"
add_param "--pipeline-parallel-size"        "${PIPELINE_PARALLEL_SIZE:-1}"
add_param "--distributed-executor-backend"  "${DISTRIBUTED_EXECUTOR_BACKEND:-}"
add_param "--worker-cls"                    "${WORKER_CLS:-}"

# --- Performance, Caching & Compilation ---
add_param "--attention-backend"             "${ATTENTION_BACKEND:-}"
add_toggle "--enable-prefix-caching" "--no-enable-prefix-caching" "${ENABLE_PREFIX_CACHING:-}"
add_bool  "--disable-log-stats"             "${DISABLE_LOG_STATS:-}"
add_param "--compilation-config"            "${COMPILATION_CONFIG:-}"
add_bool  "--enforce-eager"                 "${ENFORCE_EAGER:-}"
add_param "--device"                        "${DEVICE:-}"

# --- Scheduling & Batching ---
add_param "--max-num-seqs"                  "${MAX_NUM_SEQS:-}"
add_param "--max-num-batched-tokens"        "${MAX_NUM_BATCHED_TOKENS:-}"
add_param "--scheduling-policy"             "${SCHEDULING_POLICY:-}"
add_toggle "--enable-chunked-prefill" "--no-enable-chunked-prefill" "${ENABLE_CHUNKED_PREFILL:-}"
add_param "--num-scheduler-steps"           "${NUM_SCHEDULER_STEPS:-}"

# --- Generation & Sampling ---
add_param "--max-logprobs"                  "${MAX_LOGPROBS:-}"
add_param "--chat-template"                 "${CHAT_TEMPLATE:-}"

# --- LoRA (Adapters) ---
add_bool  "--enable-lora"                   "${ENABLE_LORA:-}"
add_param "--max-loras"                     "${MAX_LORAS:-}"
add_param "--max-lora-rank"                 "${MAX_LORA_RANK:-}"

# --- Multimodal & Embeddings ---
add_bool  "--enable-prompt-embeds"          "${ENABLE_PROMPT_EMBEDS:-}"
add_param "--limit-mm-per-prompt"           "${LIMIT_MM_PER_PROMPT:-}"
add_param "--runner"                        "${RUNNER:-}"
add_param "--mm-processor-kwargs"           "${MM_PROCESSOR_KWARGS:-}"

# --- Structured Output & Tool Use ---
add_param "--reasoning-parser"              "${REASONING_PARSER:-}"
add_bool  "--enable-auto-tool-choice"       "${ENABLE_AUTO_TOOL_CHOICE:-}"
add_param "--tool-call-parser"              "${TOOL_CALL_PARSER:-}"

# ----------------------------------------------------------------------------
# 4. Extra args support
# ----------------------------------------------------------------------------
# Note: EXTRA_ARGS is split by shell-like word splitting, so avoid using it for
# JSON arguments with spaces. Prefer dedicated env vars like SPECULATIVE_CONFIG
# and MM_PROCESSOR_KWARGS for JSON payloads. vLLM expects these as JSON strings.
# [web:1][web:13][web:14]

if [ -n "${EXTRA_ARGS:-}" ]; then
    read -r -a EXTRA_ARRAY <<< "${EXTRA_ARGS}"
    CMD+=("${EXTRA_ARRAY[@]}")
fi

# ----------------------------------------------------------------------------
# 5. Execution
# ----------------------------------------------------------------------------

echo "--- Executing Command ---"
print_cmd
echo "-------------------------"

exec "${CMD[@]}"
