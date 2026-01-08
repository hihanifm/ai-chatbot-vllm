#!/bin/bash

# Start vLLM OpenAI-compatible API server in background
# Usage: ./start_vllm.sh [model_name] [port] [host]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Determine Python executable (use venv Python if available, otherwise system Python)
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
    PYTHON_EXE="$VENV_DIR/bin/python"
    # Activate virtual environment for PATH and other env vars
    source "$VENV_DIR/bin/activate"
else
    PYTHON_EXE="python3"
    if ! command -v python3 &> /dev/null; then
        PYTHON_EXE="python"
    fi
fi

MODEL_NAME="${1:-mistralai/Mistral-7B-Instruct-v0.1}"
PORT="${2:-8000}"
HOST="${3:-0.0.0.0}"

# Create PID and log directories
PID_DIR="$SCRIPT_DIR/.pids"
LOG_DIR="$SCRIPT_DIR/.logs"
mkdir -p "$PID_DIR" "$LOG_DIR"

PID_FILE="$PID_DIR/vllm_${PORT}.pid"
LOG_FILE="$LOG_DIR/vllm_${PORT}.log"

echo "🚀 Starting vLLM Server (Background)"
echo "====================================="
echo "📦 Model: $MODEL_NAME"
echo "🌐 Host: $HOST"
echo "🔌 Port: $PORT"
echo ""

# Check if vLLM is installed
if ! "$PYTHON_EXE" -m vllm --help &> /dev/null; then
    echo "❌ Error: vLLM is not installed"
    echo "💡 Run setup first: ./setup.sh"
    exit 1
fi

# Check GPU/CUDA availability
GPU_AVAILABLE=false
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi &> /dev/null; then
        GPU_AVAILABLE=true
        echo "✅ NVIDIA GPU detected"
        nvidia-smi --query-gpu=name --format=csv,noheader | head -1 | xargs echo "   GPU:"
    else
        echo "⚠️  nvidia-smi found but GPU not accessible"
    fi
else
    echo "ℹ️  NVIDIA drivers not detected (will check CUDA availability)"
fi

# Check CUDA availability in Python
if "$PYTHON_EXE" -c "import torch; print('CUDA available:', torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
    GPU_AVAILABLE=true
    echo "✅ CUDA is available"
elif [ "$GPU_AVAILABLE" = false ]; then
    echo "⚠️  CUDA not available - vLLM may fall back to CPU mode"
fi

echo ""

# Check if port is already in use
if command -v lsof &> /dev/null; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Warning: Port $PORT is already in use"
        echo "   Stop the existing service or use a different port"
        exit 1
    fi
fi

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "⚠️  Warning: vLLM server appears to be already running (PID: $OLD_PID)"
        echo "   Stop it first: ./stop_services.sh"
        exit 1
    else
        # Stale PID file, remove it
        rm -f "$PID_FILE"
    fi
fi

# Build vLLM command with GPU detection
VLLM_CMD=(
    "$PYTHON_EXE" -m vllm.entrypoints.openai.api_server
    --model "$MODEL_NAME"
    --host "$HOST"
    --port "$PORT"
    --served-model-name "$MODEL_NAME"
)

# Add GPU-related flags if needed
# If CUDA_VISIBLE_DEVICES is set, respect it
if [ -n "$CUDA_VISIBLE_DEVICES" ]; then
    echo "   Using CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES"
fi

# If VLLM_WORKER_MULTIPROC_METHOD is set (useful for some GPU setups)
if [ -n "$VLLM_WORKER_MULTIPROC_METHOD" ]; then
    export VLLM_WORKER_MULTIPROC_METHOD
fi

# Start vLLM server in background
echo "🔄 Starting server in background..."
echo "   Using Python: $PYTHON_EXE"
echo "   Command: ${VLLM_CMD[*]}"
echo ""

# Export environment variables that might help with NVML initialization
export PYTHONUNBUFFERED=1

nohup env "${VLLM_CMD[@]}" > "$LOG_FILE" 2>&1 &

VLLM_PID=$!

# Save PID
echo $VLLM_PID > "$PID_FILE"

# Wait a moment to check if process started successfully
sleep 2

if kill -0 $VLLM_PID 2>/dev/null; then
    echo "✅ vLLM server process started!"
    echo "   PID: $VLLM_PID"
    echo "   Log: $LOG_FILE"
    echo "   PID File: $PID_FILE"
    echo ""
    echo "⏳ Waiting a few seconds to check for errors..."
    sleep 5
    
    # Check if process is still running and check logs for common errors
    if kill -0 $VLLM_PID 2>/dev/null; then
        # Check for NVML errors in logs
        if grep -qi "nvml\|can't init nvml" "$LOG_FILE" 2>/dev/null; then
            echo ""
            echo "⚠️  Warning: NVML initialization issue detected in logs"
            echo "   This is often non-fatal - vLLM may continue with limited GPU features"
            echo "   The server should still work, but GPU monitoring may be unavailable"
            echo ""
            echo "💡 If the server fails to start, check:"
            echo "   1. NVIDIA drivers: nvidia-smi"
            echo "   2. CUDA installation: nvcc --version"
            echo "   3. Full logs: cat $LOG_FILE"
            echo ""
        fi
        
        echo "✅ vLLM server appears to be running!"
        echo ""
        echo "💡 View logs: tail -f $LOG_FILE"
        echo "💡 Stop server: ./stop_services.sh"
    else
        echo ""
        echo "❌ Error: vLLM server process died"
        echo "   Check logs: cat $LOG_FILE"
        if [ -f "$LOG_FILE" ]; then
            echo ""
            echo "   Last few lines of log:"
            tail -20 "$LOG_FILE" | sed 's/^/   /'
        fi
        rm -f "$PID_FILE"
        exit 1
    fi
else
    echo "❌ Error: Failed to start vLLM server"
    echo "   Check logs: cat $LOG_FILE"
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "   Log contents:"
        cat "$LOG_FILE" | sed 's/^/   /'
    fi
    rm -f "$PID_FILE"
    exit 1
fi
