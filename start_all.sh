#!/bin/bash

# Start both vLLM server and Streamlit app together
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

# Cleanup function
cleanup() {
    echo ""
    echo "🛑 Shutting down services..."
    "$SCRIPT_DIR/stop_services.sh" 2>/dev/null || true
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGINT SIGTERM

echo "🚀 Starting vLLM + Streamlit Chatbot"
echo "====================================="
echo ""

# Start vLLM server in background
echo "📦 Starting vLLM server..."
"$SCRIPT_DIR/start_vllm.sh" "$MODEL_NAME" "$VLLM_PORT" 0.0.0.0 > /tmp/vllm.log 2>&1 &
VLLM_PID=$!

echo "   PID: $VLLM_PID"
echo "   Log: /tmp/vllm.log"
echo ""

# Wait for vLLM to be ready
echo "⏳ Waiting for vLLM server to be ready..."
MAX_RETRIES=60
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    # Check if process is still running
    if ! kill -0 $VLLM_PID 2>/dev/null; then
        echo ""
        echo "❌ Error: vLLM server process died"
        echo "   Check logs: cat /tmp/vllm.log"
        cleanup
        exit 1
    fi
    
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
    echo "   Check logs: tail -f /tmp/vllm.log"
fi

echo ""
echo "🌐 Starting Streamlit web interface..."
echo "   URL: http://localhost:$STREAMLIT_PORT"
echo ""

# Start Streamlit in foreground
"$SCRIPT_DIR/start_streamlit.sh" "$STREAMLIT_PORT"

# Cleanup when Streamlit exits
cleanup
