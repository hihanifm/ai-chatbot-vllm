#!/bin/bash

# Check status of vLLM and Streamlit services
# Usage: ./check_services.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPT_DIR/.pids"
VLLM_PORT="${VLLM_PORT:-8000}"
STREAMLIT_PORT="${STREAMLIT_PORT:-8501}"

echo "🔍 Service Status Check"
echo "======================"
echo ""

RUNNING=0

# Check vLLM using PID files
if [ -d "$PID_DIR" ]; then
    for PID_FILE in "$PID_DIR"/vllm_*.pid; do
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            PORT=$(basename "$PID_FILE" | sed 's/vllm_\(.*\)\.pid/\1/')
            if kill -0 "$PID" 2>/dev/null; then
                echo "✅ vLLM Server: RUNNING"
                echo "   PID: $PID"
                echo "   Port: $PORT"
                if command -v curl &> /dev/null; then
                    if curl -s "http://localhost:$PORT/v1/models" > /dev/null 2>&1; then
                        echo "   ✅ API responding on port $PORT"
                        # Try to get model info
                        MODEL_INFO=$(curl -s "http://localhost:$PORT/v1/models" 2>/dev/null | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "unknown")
                        if [ -n "$MODEL_INFO" ] && [ "$MODEL_INFO" != "unknown" ]; then
                            echo "   📦 Model: $MODEL_INFO"
                        fi
                    else
                        echo "   ⚠️  API not responding on port $PORT"
                    fi
                fi
                echo "   Log: .logs/vllm_${PORT}.log"
                RUNNING=$((RUNNING + 1))
            else
                echo "❌ vLLM Server: NOT RUNNING (stale PID file)"
                rm -f "$PID_FILE"
            fi
        fi
    done
fi

# Check Streamlit using PID files
if [ -d "$PID_DIR" ]; then
    for PID_FILE in "$PID_DIR"/streamlit_*.pid; do
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            PORT=$(basename "$PID_FILE" | sed 's/streamlit_\(.*\)\.pid/\1/')
            if kill -0 "$PID" 2>/dev/null; then
                echo ""
                echo "✅ Streamlit: RUNNING"
                echo "   PID: $PID"
                echo "   Port: $PORT"
                if command -v curl &> /dev/null; then
                    if curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
                        echo "   ✅ Web UI accessible on port $PORT"
                        echo "   🌐 URL: http://localhost:$PORT"
                    else
                        echo "   ⚠️  Web UI not accessible on port $PORT"
                    fi
                fi
                echo "   Log: .logs/streamlit_${PORT}.log"
                RUNNING=$((RUNNING + 1))
            else
                echo ""
                echo "❌ Streamlit: NOT RUNNING (stale PID file)"
                rm -f "$PID_FILE"
            fi
        fi
    done
fi

# Fallback: Check by process name if no PID files found
if [ $RUNNING -eq 0 ]; then
    VLLM_PIDS=$(pgrep -f "vllm.entrypoints.openai.api_server" 2>/dev/null || true)
    if [ -n "$VLLM_PIDS" ]; then
        echo "✅ vLLM Server: RUNNING (by process name)"
        echo "   PIDs: $VLLM_PIDS"
        RUNNING=$((RUNNING + 1))
    else
        echo "❌ vLLM Server: NOT RUNNING"
    fi
    
    STREAMLIT_PIDS=$(pgrep -f "streamlit run" 2>/dev/null || true)
    if [ -n "$STREAMLIT_PIDS" ]; then
        echo ""
        echo "✅ Streamlit: RUNNING (by process name)"
        echo "   PIDs: $STREAMLIT_PIDS"
        RUNNING=$((RUNNING + 1))
    else
        echo ""
        echo "❌ Streamlit: NOT RUNNING"
    fi
fi

echo ""
if [ $RUNNING -eq 0 ]; then
    echo "💡 No services running. Start with: ./start_all.sh"
else
    echo "💡 Management commands:"
    echo "   View logs: tail -f .logs/*.log"
    echo "   Stop all:  ./stop_services.sh"
fi
