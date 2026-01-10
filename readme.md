# 🚀 Universal vLLM Server

Production-grade, OpenAI-compatible server using **vLLM v0.13.0**. Deploy LLMs, Embeddings, or Vision models via environment variables.

### 🌟 Features

* **Universal**: Supports `Llama-3`, `Qwen-VL`, `BGE-M3`, `DeepSeek-R1`, and more.
* **Performance**: Pre-configured with FlashInfer, Flash Attention 2, and PagedAttention.
* **Ready to Use**: Includes SSH (`root:runpod`) and standard OpenAI API compatibility.

## ⚡ Quick Start

1. **Select Template** and set the **`MODEL`** variable (e.g., `Qwen/Qwen2.5-7B-Instruct`).
2. **Deploy**: API available on **Port 8000**.

---

## 🛠️ Parameter Reference

CLI flags map to **UPPERCASE** env vars (e.g., `--max-model-len` → `MAX_MODEL_LEN`).

### 🧠 1. Model & Weights

| Variable              | Default   | Description                                                   |
| :-------------------- | :-------- | :------------------------------------------------------------ |
| **`MODEL`**   | *(Req)* | HF Model ID (e.g.,`Qwen/Qwen2.5-7B-Instruct`).              |
| `SERVED_MODEL_NAME` | `MODEL` | Name returned in API responses.                               |
| `TRUST_REMOTE_CODE` | `true`  | Required for models like Qwen or DeepSeek.                    |
| `DTYPE`             | `auto`  | Data type:`half`, `float16`, `bfloat16`, `float`.     |
| `MAX_MODEL_LEN`     | `auto`  | Max context length. Reduce if you hit OOM errors.             |
| `LOAD_FORMAT`       | `auto`  | `safetensors`, `pt`, `bitsandbytes`, `npcache`.       |
| `ENFORCE_EAGER`     | `false` | Set `true` to disable CUDA Graphs and fix specific crashes. |

### 🚀 2. Hardware & Parallelism

| Variable                           | Default  | Description                                               |
| :--------------------------------- | :------- | :-------------------------------------------------------- |
| **`TENSOR_PARALLEL_SIZE`** | `1`    | **Set to your number of GPUs**.                     |
| `GPU_MEMORY_UTILIZATION`         | `0.90` | VRAM fraction (0.0-1.0). Use `0.95` for max efficiency. |
| `DISTRIBUTED_EXECUTOR_BACKEND`   | `mp`   | Use `mp` (multiprocessing) or `ray`.                  |
| `DEVICE`                         | `cuda` | `cuda`, `cpu`, or `neuron`.                         |

### 📉 3. Quantization & Memory

| Variable           | Default  | Description                                   |
| :----------------- | :------- | :-------------------------------------------- |
| `QUANTIZATION`   | `None` | `awq`, `gptq`, `fp8`, `bitsandbytes`. |
| `KV_CACHE_DTYPE` | `auto` | Use `fp8` to save VRAM on large context.    |
| `SWAP_SPACE`     | `4`    | CPU swap size in GiB for input buffering.     |
| `CPU_OFFLOAD_GB` | `0`    | GiB of model weights to offload to CPU RAM.   |

### ⚡ 4. Performance & Batching

| Variable                   | Default   | Description                                              |
| :------------------------- | :-------- | :------------------------------------------------------- |
| `ATTENTION_BACKEND`      | `None`  | Backend:`FLASHINFER`, `FLASH_ATTN`, `TRITON_ATTN`. |
| `ENABLE_PREFIX_CACHING`  | `false` | Cache system prompts to save compute.                    |
| `ENABLE_CHUNKED_PREFILL` | `false` | Improves interactivity on long prompts.                  |
| `MAX_NUM_SEQS`           | `256`   | Max simultaneous requests per batch.                     |
| `SCHEDULING_POLICY`      | `fcfs`  | `fcfs` (First-Come) or `priority`.                   |

### 🧩 5. Multimodal & RAG

| Variable                | Default  | Description                                               |
| :---------------------- | :------- | :-------------------------------------------------------- |
| `RUNNER`              | `auto` | Set to**`pooling`** for Embedding models.               |
| `LIMIT_MM_PER_PROMPT` | `None` | **Mandatory for Vision**: e.g., `{"image": 1}`.   |
| `REASONING_PARSER`    | `None` | Parser for DeepSeek-R1 style reasoning.                   |
| `TOOL_CALL_PARSER`    | `None` | Parser for tool calls (e.g.,`hermes`, `llama3_json`). |

---

## 💻 Access & Monitoring

* **SSH**: Port 22 | User: `root` | PW: `runpod`.
* **API**: Port 8000. Compatible with OpenAI Python client by changing `base_url`.
* **Logs**: Check `nvidia-smi` or logs in the RunPod console.

**Escape Hatch**: Use `EXTRA_ARGS` to pass any raw vLLM flags not listed above.

---

## 🛠️ Development & Build

The code and build configurations for this template are available here:
🔗 [Docker vLLM Server Builder Runpod](https://github.com/vishvaRam/Docker-vLLM-Server-Builder-Runpod)
