#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
if [ -f "${SCRIPT_DIR}/.env" ]; then
	set -o allexport
	. "${SCRIPT_DIR}/.env"
	set +o allexport
fi

MODEL_ARG="$1"
if [ -z "$MODEL_ARG" ]; then
	echo "Usage: $0 <model-name-or-alias>"
	echo ""
	echo "Available aliases:"
	echo "  gpt       -> gpt-oss-20b-mxfp4.gguf"
	echo "  coder     -> Qwen3-Coder_30B-A3B.gguf"
	echo ""
	echo "Or specify full model filename:"
	echo "  $0 mistral-7b-instruct-v0.2.Q4_0.gguf"
	echo ""
	echo "Current Model: $MODEL_PATH"
	exit 1
fi

MODEL_ARG_LOWER=$(echo "$MODEL_ARG" | tr '[:upper:]' '[:lower:]')

case "$MODEL_ARG_LOWER" in
gpt)
	MODEL_NAME="gpt-oss-20b-mxfp4.gguf"
	echo "Using alias 'gpt' -> $MODEL_NAME"
	echo ""
	;;
coder)
	MODEL_NAME="Qwen3-Coder_30B-A3B.gguf"
	echo "Using alias 'coder' -> $MODEL_NAME"
	echo ""
	;;
*)
	# No alias matched, use the argument as-is (assume it's a filename)
	MODEL_NAME="$MODEL_ARG"
	;;
esac

# Path in the mounted models folder
MODEL_PATH="/models/${MODEL_NAME}"

# Check if file exists inside the host's models dir (use absolute path)
if [ ! -f "${SCRIPT_DIR}/models/${MODEL_NAME}" ]; then
	echo "Model file not found: ${SCRIPT_DIR}/models/${MODEL_NAME}"
	echo ""
	echo "Available models:"
	ls -1 "${SCRIPT_DIR}/models/" | grep "\.gguf$" || echo "  No .gguf files found"
	exit 1
fi

# Update the .env file with the new model path
sed -i "s|^MODEL_PATH=.*|MODEL_PATH=${MODEL_PATH}|" "${SCRIPT_DIR}/.env"

# Change to script directory for docker-compose
cd "${SCRIPT_DIR}"

# Use docker-compose to recreate the container (this reloads env_file)
docker-compose down llama-cpp
docker-compose up -d llama-cpp

# Wait a moment for container to start
sleep 3

# Check if container is running
if docker ps | grep -q llama-cpp; then
	echo ""
	echo "Successfully restarted llama-cpp container with new model."
else
	echo ""
	echo "Container failed to start. Check logs with: docker logs llama-cpp"
	exit 1
fi
