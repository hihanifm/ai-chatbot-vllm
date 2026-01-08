#!/bin/bash

# GPU Validation Script
# Checks NVIDIA GPU, CUDA, PyTorch, and vLLM GPU support

echo "🔍 GPU Validation Check"
echo "======================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
ERRORS=0
WARNINGS=0

# Determine Python executable
if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/python" ]; then
    PYTHON_EXE="$VENV_DIR/bin/python"
    source "$VENV_DIR/bin/activate"
else
    # Try to find a compatible Python version
    PYTHON_EXE=""
    for pyver in 3.11 3.10 3.9 3.8; do
        if command -v python${pyver} &> /dev/null; then
            PYTHON_EXE="python${pyver}"
            break
        fi
    done
    
    if [ -z "$PYTHON_EXE" ]; then
        PYTHON_EXE="python3"
    fi
fi

echo "Using Python: $PYTHON_EXE"
$PYTHON_EXE --version
echo ""

# 1. Check NVIDIA GPU hardware
echo "1️⃣  Checking NVIDIA GPU Hardware"
echo "--------------------------------"
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi &> /dev/null; then
        echo "✅ nvidia-smi is available"
        echo ""
        echo "GPU Information:"
        nvidia-smi --query-gpu=name,driver_version,memory.total,compute_cap --format=csv,noheader,nounits | \
            while IFS=',' read -r name driver memory compute; do
                echo "   GPU: $name"
                echo "   Driver: $driver"
                echo "   Memory: ${memory}MB"
                echo "   Compute Capability: $compute"
                echo ""
            done
        
        # Show GPU status
        echo "GPU Status:"
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader | \
            sed 's/^/   /'
        echo ""
    else
        echo "❌ nvidia-smi found but GPU not accessible"
        echo "   This may indicate driver issues"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "❌ nvidia-smi not found"
    echo "   NVIDIA drivers may not be installed"
    ERRORS=$((ERRORS + 1))
fi

# 2. Check NVIDIA driver version
echo ""
echo "2️⃣  Checking NVIDIA Driver"
echo "--------------------------"
if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
    echo "✅ Driver Version: $DRIVER_VERSION"
    
    # Check if driver version is recent enough (CUDA 11.8+ typically needs 450.80+)
    MAJOR_VER=$(echo $DRIVER_VERSION | cut -d'.' -f1)
    if [ "$MAJOR_VER" -lt 450 ] && [ "$MAJOR_VER" -ne 0 ]; then
        echo "⚠️  Warning: Driver version may be too old for modern CUDA"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ Cannot check driver version"
fi

# 3. Check CUDA toolkit
echo ""
echo "3️⃣  Checking CUDA Toolkit"
echo "-------------------------"
if command -v nvcc &> /dev/null; then
    CUDA_VERSION=$(nvcc --version 2>/dev/null | grep "release" | sed 's/.*release \([0-9.]*\).*/\1/')
    echo "✅ CUDA Toolkit installed"
    echo "   Version: $CUDA_VERSION"
    
    # Check CUDA library
    if [ -d "/usr/local/cuda" ] || [ -d "/opt/cuda" ]; then
        echo "   CUDA path found"
    fi
else
    echo "⚠️  nvcc not found in PATH"
    echo "   CUDA toolkit may not be installed or not in PATH"
    WARNINGS=$((WARNINGS + 1))
    
    # Check common CUDA paths
    if [ -d "/usr/local/cuda" ]; then
        echo "   Found CUDA at: /usr/local/cuda"
        echo "   💡 Add to PATH: export PATH=/usr/local/cuda/bin:\$PATH"
        echo "   💡 Add to LD_LIBRARY_PATH: export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH"
    fi
fi

# 4. Check PyTorch CUDA support
echo ""
echo "4️⃣  Checking PyTorch CUDA Support"
echo "----------------------------------"
if "$PYTHON_EXE" -c "import torch" 2>/dev/null; then
    TORCH_VERSION=$("$PYTHON_EXE" -c "import torch; print(torch.__version__)" 2>/dev/null)
    CUDA_AVAILABLE=$("$PYTHON_EXE" -c "import torch; print(torch.cuda.is_available())" 2>/dev/null)
    CUDA_VERSION_PT=$("$PYTHON_EXE" -c "import torch; print(torch.version.cuda if torch.cuda.is_available() else 'N/A')" 2>/dev/null)
    
    echo "✅ PyTorch installed"
    echo "   Version: $TORCH_VERSION"
    echo "   CUDA Available: $CUDA_AVAILABLE"
    
    if [ "$CUDA_AVAILABLE" = "True" ]; then
        echo "   CUDA Version (PyTorch): $CUDA_VERSION_PT"
        GPU_COUNT=$("$PYTHON_EXE" -c "import torch; print(torch.cuda.device_count())" 2>/dev/null)
        echo "   GPU Count: $GPU_COUNT"
        
        if [ "$GPU_COUNT" -gt 0 ]; then
            echo "   GPU Device Names:"
            "$PYTHON_EXE" -c "import torch; [print(f'     [{i}] {torch.cuda.get_device_name(i)}') for i in range(torch.cuda.device_count())]" 2>/dev/null
        fi
    else
        echo "❌ CUDA not available in PyTorch"
        echo "   PyTorch may have been installed without CUDA support"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "⚠️  PyTorch not installed"
    echo "   It will be installed with vLLM"
    WARNINGS=$((WARNINGS + 1))
fi

# 5. Check vLLM installation and GPU support
echo ""
echo "5️⃣  Checking vLLM Installation"
echo "-------------------------------"
if "$PYTHON_EXE" -c "import vllm" 2>/dev/null; then
    VLLM_VERSION=$("$PYTHON_EXE" -c "import vllm; print(vllm.__version__)" 2>/dev/null)
    echo "✅ vLLM installed"
    echo "   Version: $VLLM_VERSION"
    
    # Try to check if vLLM can see GPUs
    echo ""
    echo "   Checking vLLM GPU detection..."
    if "$PYTHON_EXE" -c "from vllm.utils import get_gpu_memory, get_cuda_device_capability; print('GPU Memory:', get_gpu_memory()); print('CUDA Capability:', get_cuda_device_capability())" 2>/dev/null; then
        echo "   ✅ vLLM can access GPU information"
    else
        echo "   ⚠️  vLLM GPU detection test failed (may still work)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "❌ vLLM not installed"
    echo "   Run ./setup.sh to install"
    ERRORS=$((ERRORS + 1))
fi

# 6. Check NVML (NVIDIA Management Library)
echo ""
echo "6️⃣  Checking NVML (NVIDIA Management Library)"
echo "----------------------------------------------"
if "$PYTHON_EXE" -c "from pynvml import nvmlInit, nvmlSystemGetDriverVersion" 2>/dev/null; then
    echo "✅ pynvml (NVML Python bindings) available"
    NVML_WORKING=$("$PYTHON_EXE" -c "from pynvml import nvmlInit; nvmlInit(); print('OK')" 2>&1)
    if echo "$NVML_WORKING" | grep -q "OK"; then
        echo "   NVML initialized successfully"
    else
        echo "   ⚠️  NVML initialization issue (non-fatal):"
        echo "   $NVML_WORKING" | sed 's/^/      /'
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "ℹ️  pynvml not installed (optional)"
    echo "   NVML errors in vLLM are usually non-fatal"
fi

# 7. Check GPU memory and compute capability
echo ""
echo "7️⃣  GPU Compute Capability"
echo "--------------------------"
if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
    COMPUTE_CAPS=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader)
    echo "Compute Capabilities: $COMPUTE_CAPS"
    
    # Check if compute capability is supported (vLLM typically needs 7.0+)
    for cap in $COMPUTE_CAPS; do
        MAJOR=$(echo $cap | cut -d'.' -f1)
        if [ "$MAJOR" -lt 7 ]; then
            echo "⚠️  Warning: Compute capability $cap may not be fully supported"
            echo "   vLLM typically requires 7.0+ (Volta/Turing/Ampere/Ada/Hopper)"
            WARNINGS=$((WARNINGS + 1))
        fi
    done
fi

# Summary
echo ""
echo "═══════════════════════════════════════"
echo "📊 Summary"
echo "═══════════════════════════════════════"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All GPU checks passed! Your system is ready for vLLM."
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  GPU checks completed with $WARNINGS warning(s)"
    echo "   The system should work, but review warnings above"
else
    echo "❌ GPU checks failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo "   Please resolve the errors before using vLLM"
fi

echo ""
echo "💡 Next steps:"
if [ $ERRORS -eq 0 ]; then
    echo "   1. Run: ./setup.sh (if not done already)"
    echo "   2. Start services: ./start_all.sh"
else
    echo "   1. Install NVIDIA drivers: sudo apt install nvidia-driver-XXX"
    echo "   2. Install CUDA toolkit (if needed)"
    echo "   3. Reinstall PyTorch with CUDA support"
    echo "   4. Run this script again to verify"
fi

echo ""
