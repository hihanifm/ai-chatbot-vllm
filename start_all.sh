#!/bin/bash

# Start both vLLM server and Streamlit app together in background
# Usage: ./start_all.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Activate virtual environment
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

# Configuration (can be overridden with environment variables)
VLLM_PORT="${VLLM_PORT:-8000}"
STREAMLIT_PORT="${STREAMLIT_PORT:-8501}"
MODEL_NAME="${MODEL_NAME:-mistralai/Mistral-7B-Instruct-v0.1}"

echo "🚀 Starting vLLM + Streamlit Chatbot (Background)"
echo "=================================================="
echo ""

# Start vLLM server in background
echo "📦 Starting vLLM server..."
"$SCRIPT_DIR/start_vllm.sh" "$MODEL_NAME" "$VLLM_PORT" 0.0.0.0

if [ $? -ne 0 ]; then
    echo "❌ Failed to start vLLM server"
    exit 1
fi

# Wait for vLLM to be ready
echo ""
echo "⏳ Waiting for vLLM server to be ready..."
MAX_RETRIES=60
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Check if API is responding
    if curl -s "http://localhost:$VLLM_PORT/v1/models" > /dev/null 2>&1; then
        echo "✅ vLLM server is ready!"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
        echo "   Still waiting... ($RETRY_COUNT/$MAX_RETRIES)"
    fi
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo ""
    echo "⚠️  Warning: vLLM server didn't respond in time"
    echo "   It may still be starting. Continuing anyway..."
    echo "   Check logs: tail -f .logs/vllm_${VLLM_PORT}.log"
fi

# Start Streamlit in background
echo ""
echo "🌐 Starting Streamlit web interface..."
"$SCRIPT_DIR/start_streamlit.sh" "$STREAMLIT_PORT"

if [ $? -ne 0 ]; then
    echo "❌ Failed to start Streamlit"
    echo "🛑 Stopping vLLM server..."
    "$SCRIPT_DIR/stop_services.sh"
    exit 1
fi

echo ""
echo "✅ All services started successfully!"
echo ""
echo "📊 Service Status:"
echo "   vLLM:    http://localhost:$VLLM_PORT"
echo "   Streamlit: http://localhost:$STREAMLIT_PORT"
echo ""
echo "💡 Management commands:"
echo "   Check status: ./check_services.sh"
echo "   View logs:    tail -f .logs/*.log"
echo "   Stop all:     ./stop_services.sh"
echo ""
echo "🔍 Services are running in the background. You can close this terminal."
