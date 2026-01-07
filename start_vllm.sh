#!/bin/bash

# Start vLLM OpenAI-compatible API server
# Usage: ./start_vllm.sh [model_name] [port] [host]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Activate virtual environment
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

MODEL_NAME="${1:-mistralai/Mistral-7B-Instruct-v0.1}"
PORT="${2:-8000}"
HOST="${3:-0.0.0.0}"

echo "🚀 Starting vLLM Server"
echo "========================"
echo "📦 Model: $MODEL_NAME"
echo "🌐 Host: $HOST"
echo "🔌 Port: $PORT"
echo ""

# Check if vLLM is installed
if ! python -m vllm --help &> /dev/null; then
    echo "❌ Error: vLLM is not installed"
    echo "💡 Run setup first: ./setup.sh"
    exit 1
fi

# Check if port is already in use
if command -v lsof &> /dev/null; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Warning: Port $PORT is already in use"
        echo "   Stop the existing service or use a different port"
        exit 1
    fi
fi

# Start vLLM server
echo "🔄 Starting server..."
python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL_NAME" \
    --host "$HOST" \
    --port "$PORT" \
    --served-model-name "$MODEL_NAME"
