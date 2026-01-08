#!/bin/bash

# Stop vLLM and Streamlit services
# Usage: ./stop_services.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPT_DIR/.pids"

echo "🛑 Stopping services..."
echo ""

STOPPED=0

# Stop vLLM using PID files
if [ -d "$PID_DIR" ]; then
    for PID_FILE in "$PID_DIR"/vllm_*.pid; do
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                echo "🔄 Stopping vLLM server (PID: $PID)..."
                kill -TERM "$PID" 2>/dev/null || true
                sleep 2
                # Force kill if still running
                if kill -0 "$PID" 2>/dev/null; then
                    kill -KILL "$PID" 2>/dev/null || true
                    echo "   Force stopped"
                fi
                STOPPED=$((STOPPED + 1))
            fi
            rm -f "$PID_FILE"
        fi
    done
fi

# Stop Streamlit using PID files
if [ -d "$PID_DIR" ]; then
    for PID_FILE in "$PID_DIR"/streamlit_*.pid; do
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                echo "🔄 Stopping Streamlit (PID: $PID)..."
                kill -TERM "$PID" 2>/dev/null || true
                sleep 2
                # Force kill if still running
                if kill -0 "$PID" 2>/dev/null; then
                    kill -KILL "$PID" 2>/dev/null || true
                    echo "   Force stopped"
                fi
                STOPPED=$((STOPPED + 1))
            fi
            rm -f "$PID_FILE"
        fi
    done
fi

# Fallback: Find and kill processes by name (in case PID files are missing)
VLLM_PIDS=$(pgrep -f "vllm.entrypoints.openai.api_server" 2>/dev/null || true)
if [ -n "$VLLM_PIDS" ]; then
    echo "🔄 Stopping vLLM processes (by name)..."
    echo "$VLLM_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 2
    echo "$VLLM_PIDS" | xargs kill -KILL 2>/dev/null || true
    STOPPED=$((STOPPED + 1))
fi

STREAMLIT_PIDS=$(pgrep -f "streamlit run" 2>/dev/null || true)
if [ -n "$STREAMLIT_PIDS" ]; then
    echo "🔄 Stopping Streamlit processes (by name)..."
    echo "$STREAMLIT_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 2
    echo "$STREAMLIT_PIDS" | xargs kill -KILL 2>/dev/null || true
    STOPPED=$((STOPPED + 1))
fi

if [ $STOPPED -eq 0 ]; then
    echo "ℹ️  No running services found"
else
    echo "✅ All services stopped ($STOPPED service(s))"
fi

echo ""
