#!/bin/bash
set -e

CMD=(
    /app/llama-server
    --host 0.0.0.0
    --port "${LLAMA_PORT}"
    --model "${MODEL_PATH}"
    --threads "${THREADS}"
    -fa 1
)

case "$MODEL_PATH" in
"/models/gpt-oss-20b-mxfp4.gguf")
    CMD+=(--n-gpu-layers 99 --ctx-size ${GPT_CTX} --jinja -ub 2048,4096 -b 4096 --temp 1.0 --top-p 1.0 --top-k 0)
    ;;
"/models/Qwen3-Coder_30B-A3B.gguf")
    CMD+=(--n-gpu-layers 99 --ctx-size ${QWEN_CTX} --jinja --temp 0.7 --min-p 0.0 --top-p 0.8 --top-k 20 --repeat-penalty 1.05)
    ;;
esac

exec "${CMD[@]}"

