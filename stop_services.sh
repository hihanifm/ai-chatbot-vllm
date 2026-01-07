#!/bin/bash

# Stop vLLM and Streamlit services
# Usage: ./stop_services.sh

echo "🛑 Stopping services..."
echo ""

# Find and stop vLLM processes
VLLM_PIDS=$(pgrep -f "vllm.entrypoints.openai.api_server" 2>/dev/null || true)
if [ -n "$VLLM_PIDS" ]; then
    echo "🔄 Stopping vLLM server (PIDs: $VLLM_PIDS)..."
    echo "$VLLM_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 3
    # Force kill if still running
    REMAINING=$(echo "$VLLM_PIDS" | xargs -I {} sh -c 'kill -0 {} 2>/dev/null && echo {}' || true)
    if [ -n "$REMAINING" ]; then
        echo "$REMAINING" | xargs kill -KILL 2>/dev/null || true
        echo "   Force stopped remaining processes"
    fi
    echo "✅ vLLM server stopped"
else
    echo "ℹ️  No vLLM server process found"
fi

# Find and stop Streamlit processes
STREAMLIT_PIDS=$(pgrep -f "streamlit run" 2>/dev/null || true)
if [ -n "$STREAMLIT_PIDS" ]; then
    echo "🔄 Stopping Streamlit (PIDs: $STREAMLIT_PIDS)..."
    echo "$STREAMLIT_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 2
    # Force kill if still running
    REMAINING=$(echo "$STREAMLIT_PIDS" | xargs -I {} sh -c 'kill -0 {} 2>/dev/null && echo {}' || true)
    if [ -n "$REMAINING" ]; then
        echo "$REMAINING" | xargs kill -KILL 2>/dev/null || true
        echo "   Force stopped remaining processes"
    fi
    echo "✅ Streamlit stopped"
else
    echo "ℹ️  No Streamlit process found"
fi

echo ""
echo "✅ All services stopped"
