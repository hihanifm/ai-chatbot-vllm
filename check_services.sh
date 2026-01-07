#!/bin/bash

# Check status of vLLM and Streamlit services
# Usage: ./check_services.sh

VLLM_PORT="${VLLM_PORT:-8000}"
STREAMLIT_PORT="${STREAMLIT_PORT:-8501}"

echo "🔍 Service Status Check"
echo "======================"
echo ""

# Check vLLM
VLLM_PIDS=$(pgrep -f "vllm.entrypoints.openai.api_server" 2>/dev/null || true)
if [ -n "$VLLM_PIDS" ]; then
    echo "✅ vLLM Server: RUNNING"
    echo "   PIDs: $VLLM_PIDS"
    if command -v curl &> /dev/null; then
        if curl -s "http://localhost:$VLLM_PORT/v1/models" > /dev/null 2>&1; then
            echo "   ✅ API responding on port $VLLM_PORT"
            # Try to get model info
            MODEL_INFO=$(curl -s "http://localhost:$VLLM_PORT/v1/models" 2>/dev/null | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
            if [ -n "$MODEL_INFO" ] && [ "$MODEL_INFO" != "unknown" ]; then
                echo "   📦 Model: $MODEL_INFO"
            fi
        else
            echo "   ⚠️  API not responding on port $VLLM_PORT"
        fi
    fi
else
    echo "❌ vLLM Server: NOT RUNNING"
fi

echo ""

# Check Streamlit
STREAMLIT_PIDS=$(pgrep -f "streamlit run" 2>/dev/null || true)
if [ -n "$STREAMLIT_PIDS" ]; then
    echo "✅ Streamlit: RUNNING"
    echo "   PIDs: $STREAMLIT_PIDS"
    if command -v curl &> /dev/null; then
        if curl -s "http://localhost:$STREAMLIT_PORT" > /dev/null 2>&1; then
            echo "   ✅ Web UI accessible on port $STREAMLIT_PORT"
            echo "   🌐 URL: http://localhost:$STREAMLIT_PORT"
        else
            echo "   ⚠️  Web UI not accessible on port $STREAMLIT_PORT"
        fi
    fi
else
    echo "❌ Streamlit: NOT RUNNING"
fi

echo ""
echo "💡 To start services: ./start_all.sh"
echo "💡 To stop services: ./stop_services.sh"
