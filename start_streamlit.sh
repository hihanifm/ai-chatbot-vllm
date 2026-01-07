#!/bin/bash

# Start Streamlit web application
# Usage: ./start_streamlit.sh [port] [app_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Activate virtual environment
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

PORT="${1:-8501}"
APP_FILE="${2:-main.py}"

echo "🌐 Starting Streamlit App"
echo "========================="
echo "📄 App: $APP_FILE"
echo "🔌 Port: $PORT"
echo ""

# Check if Streamlit is installed
if ! python -m streamlit --help &> /dev/null; then
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

# Start Streamlit
echo "🔄 Starting web interface..."
echo ""
streamlit run "$APP_FILE" \
    --server.port "$PORT" \
    --server.headless true \
    --browser.gatherUsageStats false
