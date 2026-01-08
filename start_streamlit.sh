#!/bin/bash

# Start Streamlit web application in background
# Usage: ./start_streamlit.sh [port] [app_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Determine Python executable (use venv Python if available, otherwise find compatible Python)
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
    PYTHON_EXE="$VENV_DIR/bin/python"
    STREAMLIT_EXE="$VENV_DIR/bin/streamlit"
    # Activate virtual environment for PATH and other env vars
    source "$VENV_DIR/bin/activate"
else
    # Try to find a compatible Python version (for consistency with vLLM requirements)
    PYTHON_EXE=""
    for pyver in 3.11 3.10 3.9 3.8; do
        if command -v python${pyver} &> /dev/null; then
            PYTHON_EXE="python${pyver}"
            break
        fi
    done
    
    if [ -z "$PYTHON_EXE" ]; then
        PYTHON_EXE="python3"
        if ! command -v python3 &> /dev/null; then
            PYTHON_EXE="python"
        fi
    fi
    
    STREAMLIT_EXE="streamlit"
fi

PORT="${1:-8501}"
APP_FILE="${2:-main.py}"

# Create PID and log directories
PID_DIR="$SCRIPT_DIR/.pids"
LOG_DIR="$SCRIPT_DIR/.logs"
mkdir -p "$PID_DIR" "$LOG_DIR"

PID_FILE="$PID_DIR/streamlit_${PORT}.pid"
LOG_FILE="$LOG_DIR/streamlit_${PORT}.log"

echo "🌐 Starting Streamlit App (Background)"
echo "======================================="
echo "📄 App: $APP_FILE"
echo "🔌 Port: $PORT"
echo ""

# Check if Streamlit is installed
if ! "$PYTHON_EXE" -m streamlit --help &> /dev/null && ! command -v "$STREAMLIT_EXE" &> /dev/null; then
    echo "❌ Error: Streamlit is not installed"
    echo "💡 Run setup first: ./setup.sh"
    exit 1
fi

# Check if app file exists
if [ ! -f "$APP_FILE" ]; then
    echo "❌ Error: App file '$APP_FILE' not found"
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

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "⚠️  Warning: Streamlit appears to be already running (PID: $OLD_PID)"
        echo "   Stop it first: ./stop_services.sh"
        exit 1
    else
        # Stale PID file, remove it
        rm -f "$PID_FILE"
    fi
fi

# Start Streamlit in background
echo "🔄 Starting web interface in background..."
echo "   Using Python: $PYTHON_EXE"
# Use streamlit executable if available, otherwise use python -m streamlit
if command -v "$STREAMLIT_EXE" &> /dev/null; then
    nohup "$STREAMLIT_EXE" run "$APP_FILE" \
        --server.port "$PORT" \
        --server.headless true \
        --browser.gatherUsageStats false \
        > "$LOG_FILE" 2>&1 &
else
    nohup "$PYTHON_EXE" -m streamlit run "$APP_FILE" \
        --server.port "$PORT" \
        --server.headless true \
        --browser.gatherUsageStats false \
        > "$LOG_FILE" 2>&1 &
fi

STREAMLIT_PID=$!

# Save PID
echo $STREAMLIT_PID > "$PID_FILE"

# Wait a moment to check if process started successfully
sleep 2

if kill -0 $STREAMLIT_PID 2>/dev/null; then
    echo "✅ Streamlit started successfully!"
    echo "   PID: $STREAMLIT_PID"
    echo "   Log: $LOG_FILE"
    echo "   PID File: $PID_FILE"
    echo "   URL: http://localhost:$PORT"
    echo ""
    echo "💡 View logs: tail -f $LOG_FILE"
    echo "💡 Stop app: ./stop_services.sh"
else
    echo "❌ Error: Failed to start Streamlit"
    echo "   Check logs: cat $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi
