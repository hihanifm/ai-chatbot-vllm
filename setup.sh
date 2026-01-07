#!/bin/bash

# Setup script for vLLM + Streamlit Chatbot
# Optimized for Linux systems

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

echo "🔧 Setting up vLLM + Streamlit Chatbot"
echo "======================================"
echo ""

# Check Python version
echo "🐍 Checking Python version..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "💡 Install Python 3.8-3.11 with your package manager:"
    echo "   Ubuntu/Debian: sudo apt install python3.11 python3.11-venv"
    echo "   Fedora/RHEL: sudo dnf install python3.11"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

echo "✅ Found Python $PYTHON_VERSION"

# Check Python version compatibility
if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 12 ]; then
    echo ""
    echo "⚠️  Warning: Python $PYTHON_VERSION may have compatibility issues with vLLM"
    echo "   vLLM officially supports Python 3.8-3.11"
    echo ""
    echo "💡 Recommended: Use Python 3.11 for best compatibility"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    echo ""
elif [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ] && [ "$PYTHON_MINOR" -le 11 ]; then
    echo "✅ Python version is compatible with vLLM"
    echo ""
else
    echo "⚠️  Warning: Python $PYTHON_VERSION may not be supported"
    echo ""
fi

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source "$VENV_DIR/bin/activate"
echo "✅ Virtual environment activated"
echo ""

# Upgrade pip and essential tools
echo "⬆️  Upgrading pip and build tools..."
pip install --upgrade pip setuptools wheel
echo ""

# Install vLLM
echo "📦 Installing vLLM..."
echo "   This may take a few minutes..."
if pip install --no-cache-dir vllm 2>&1 | tee /tmp/vllm_install.log; then
    echo "✅ vLLM installed successfully"
    VLLM_INSTALLED=true
else
    echo ""
    echo "❌ vLLM installation failed"
    echo ""
    echo "💡 Troubleshooting:"
    echo "   1. Ensure you have CUDA installed (for GPU support)"
    echo "   2. Check if your system meets vLLM requirements"
    echo "   3. See error log: cat /tmp/vllm_install.log"
    echo "   4. Visit: https://docs.vllm.ai/en/latest/getting_started/installation.html"
    echo ""
    VLLM_INSTALLED=false
    read -p "Continue with other dependencies anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo ""

# Install other dependencies
echo "📦 Installing other dependencies..."
pip install -r "$SCRIPT_DIR/requirements.txt"
echo "✅ Dependencies installed"
echo ""

# Verify installations
echo "🔍 Verifying installations..."
echo ""

ERRORS=0

if python3 -c "import streamlit" 2>/dev/null; then
    STREAMLIT_VERSION=$(python3 -c "import streamlit; print(streamlit.__version__)")
    echo "✅ Streamlit: $STREAMLIT_VERSION"
else
    echo "❌ Streamlit: Not found"
    ERRORS=$((ERRORS + 1))
fi

if python3 -c "import langchain" 2>/dev/null; then
    LANGCHAIN_VERSION=$(python3 -c "import langchain; print(langchain.__version__)")
    echo "✅ LangChain: $LANGCHAIN_VERSION"
else
    echo "❌ LangChain: Not found"
    ERRORS=$((ERRORS + 1))
fi

if python3 -c "import vllm" 2>/dev/null; then
    VLLM_VERSION=$(python3 -c "import vllm; print(vllm.__version__)")
    echo "✅ vLLM: $VLLM_VERSION"
elif [ "$VLLM_INSTALLED" = false ]; then
    echo "⚠️  vLLM: Installation was skipped or failed"
    ERRORS=$((ERRORS + 1))
else
    echo "❌ vLLM: Not found or import failed"
    ERRORS=$((ERRORS + 1))
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "✅ Setup complete! All dependencies are installed."
    echo ""
    echo "📝 Next steps:"
    echo "   1. Start all services: ./start_all.sh"
    echo "   2. Or start separately:"
    echo "      ./start_vllm.sh        # Terminal 1"
    echo "      ./start_streamlit.sh   # Terminal 2"
    echo ""
else
    echo "⚠️  Setup completed with $ERRORS error(s)."
    echo "💡 Check the error messages above for troubleshooting."
    exit 1
fi
