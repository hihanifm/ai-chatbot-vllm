# Streamlit + LangChain + vLLM Chatbot

Run your own AI Chatbot locally on a Linux system with GPU support.

This project uses the [Mistral 7B](https://mistral.ai/news/announcing-mistral-7b/) model with [vLLM](https://vllm.ai) as the high-performance inference engine, which provides an OpenAI-compatible API. LangChain connects to this API to power a Streamlit-based chat interface.

## Features

- 🤖 **Local AI Chatbot** - Run your own LLM-powered chatbot
- 🎨 **Modern UI** - Beautiful Streamlit interface with chat history
- ⚙️ **Configurable** - Adjust model, temperature, max tokens, and system prompts
- 📝 **Chat Memory** - Maintains conversation context
- 🚀 **Easy Management** - Simple utility scripts to start/stop services
- 🐧 **Linux Optimized** - Designed for Linux systems with GPU support

## Prerequisites

- **Linux** (Ubuntu, Debian, Fedora, RHEL, or similar)
- **Python 3.8-3.11** (Python 3.11 recommended)
  - Ubuntu/Debian: `sudo apt install python3.11 python3.11-venv`
  - Fedora/RHEL: `sudo dnf install python3.11`
- **CUDA-capable GPU** (recommended) or CPU
- `curl` and standard Linux utilities

## Quick Start

### 1. Setup (One-time installation)

Run the setup script to automatically create a virtual environment and install all dependencies:

```bash
./setup.sh
```

This script will:
- ✅ Check Python version
- ✅ Create a virtual environment (`.venv`)
- ✅ Install/upgrade pip and build tools
- ✅ Install vLLM and all dependencies
- ✅ Verify all installations

### 2. Start the Services

#### Option A: Start Everything at Once (Recommended)

```bash
./start_all.sh
```

This script will:
1. Start the vLLM server in the background
2. Wait for it to be ready
3. Start the Streamlit app
4. Clean up both services when you stop (Ctrl+C)

#### Option B: Start Services Separately

**Terminal 1 - Start vLLM server:**
```bash
./start_vllm.sh
```

**Terminal 2 - Start Streamlit app:**
```bash
./start_streamlit.sh
```

### 3. Access the Application

Once started, open your browser and navigate to:
- **Streamlit UI:** http://localhost:8501
- **vLLM API:** http://localhost:8000

### 4. Stop the Services

```bash
./stop_services.sh
```

Or manually stop with Ctrl+C in each terminal.

### 5. Check Service Status

```bash
./check_services.sh
```

## Utility Scripts

| Script | Description |
|--------|-------------|
| `setup.sh` | **First-time setup** - Create venv and install all dependencies |
| `start_all.sh` | Start both vLLM server and Streamlit app |
| `start_vllm.sh` | Start only the vLLM server |
| `start_streamlit.sh` | Start only the Streamlit app |
| `stop_services.sh` | Stop all running services |
| `check_services.sh` | Check status of running services |

**Note:** All scripts automatically activate the virtual environment, so you don't need to run `source .venv/bin/activate` manually.

### Script Options

**start_vllm.sh:**
```bash
./start_vllm.sh [model_name] [port] [host]
# Example: ./start_vllm.sh mistralai/Mistral-7B-Instruct-v0.1 8000 0.0.0.0
```

**start_streamlit.sh:**
```bash
./start_streamlit.sh [port] [app_file]
# Example: ./start_streamlit.sh 8501 main.py
```

**Environment Variables:**
```bash
export VLLM_PORT=8000
export STREAMLIT_PORT=8501
export MODEL_NAME=mistralai/Mistral-7B-Instruct-v0.1
```

## Configuration

The Streamlit app includes a sidebar with configuration options:

- **System Prompt** - Define the AI's personality and behavior
- **Model Name** - Change the model (must match vLLM server model)
- **API Base URL** - vLLM server endpoint (default: http://localhost:8000/v1)
- **Temperature** - Control randomness (0.0 = deterministic, 2.0 = very random)
- **Max Tokens** - Maximum response length
- **Clear Chat History** - Reset conversation

## Troubleshooting

### vLLM Server Issues

**Issue:** vLLM fails to start
- **Solution:** Ensure CUDA is properly installed (for GPU support)
  ```bash
  nvidia-smi  # Check if GPU is detected
  ```
- Check vLLM installation: `python -m vllm --help`
- See vLLM docs: https://docs.vllm.ai/en/latest/getting_started/installation.html

**Issue:** Out of memory
- **Solution:** Use a smaller model or reduce `--max-model-len` parameter
- For CPU-only: vLLM may be slow or have limited support

**Issue:** "can't init nvml" or NVML initialization errors
- **Note:** This warning is often non-fatal - vLLM may still work
- **Possible causes:**
  - NVIDIA drivers installed but NVML library not accessible
  - Permissions issues with GPU access
  - Driver/kernel mismatch
- **Solutions:**
  ```bash
  # Check GPU is accessible
  nvidia-smi
  
  # Check CUDA availability
  python -c "import torch; print(torch.cuda.is_available())"
  
  # Check driver status
  lsmod | grep nvidia
  
  # If needed, reinstall NVIDIA drivers
  # For Ubuntu/Debian:
  sudo apt update
  sudo apt install --reinstall nvidia-driver-XXX  # Replace XXX with your driver version
  ```
- **If vLLM still starts:** The NVML error is usually just a warning about GPU monitoring, not a fatal error. The server should still work.

**Issue:** Port already in use
- **Solution:** Stop existing service or use a different port
  ```bash
  ./stop_services.sh
  # Or use a different port: ./start_vllm.sh mistralai/Mistral-7B-Instruct-v0.1 8001
  ```

### Streamlit Connection Issues

**Issue:** "Error: Connection refused"
- **Solution:** Ensure vLLM server is running on the correct port
- Check with: `./check_services.sh` or `curl http://localhost:8000/v1/models`

**Issue:** Model not found
- **Solution:** Ensure the model name in Streamlit matches the one loaded in vLLM
- Check vLLM logs for loaded model name

### General Issues

**Check service status:**
```bash
./check_services.sh
```

**View running processes:**
```bash
ps aux | grep vllm
ps aux | grep streamlit
```

**View vLLM logs:**
```bash
tail -f /tmp/vllm.log
```

**Kill processes manually:**
```bash
pkill -f vllm
pkill -f streamlit
```

## Project Structure

```
.
├── main.py                 # Streamlit application
├── requirements.txt        # Python dependencies
├── setup.sh               # Setup script
├── start_all.sh           # Start both services
├── start_vllm.sh          # Start vLLM server
├── start_streamlit.sh     # Start Streamlit app
├── stop_services.sh       # Stop all services
├── check_services.sh      # Check service status
└── README.md              # This file
```

## Dependencies

- **streamlit** (>=1.39.0) - Web UI framework
- **langchain** (>=0.3.0) - LLM orchestration
- **langchain-openai** (>=0.2.0) - OpenAI API integration
- **langchain-core** (>=0.3.0) - LangChain core components
- **openai** (>=1.54.0) - OpenAI API client
- **vllm** - High-performance LLM inference (installed separately)
- **psutil** (>=5.9.0) - System utilities

## Advanced Usage

### Using Different Models

Change the model in both the vLLM server and Streamlit app:

```bash
# Start vLLM with a different model
./start_vllm.sh meta-llama/Llama-2-7b-chat-hf

# Update model name in Streamlit sidebar (or restart with MODEL_NAME env var)
export MODEL_NAME=meta-llama/Llama-2-7b-chat-hf
./start_all.sh
```

### Custom vLLM Parameters

Edit `start_vllm.sh` to add additional vLLM parameters:

```bash
python -m vllm.entrypoints.openai.api_server \
    --model "$MODEL_NAME" \
    --host "$HOST" \
    --port "$PORT" \
    --tensor-parallel-size 2 \      # For multi-GPU
    --gpu-memory-utilization 0.9 \  # GPU memory usage
    --max-model-len 4096            # Max sequence length
```

### Running in Production

For production deployments:

1. Use a reverse proxy (nginx) in front of Streamlit
2. Run vLLM with proper resource limits
3. Set up proper logging and monitoring
4. Use environment variables for sensitive configuration
5. Consider using a process manager (systemd, supervisord)
6. Enable authentication for the vLLM API

### Systemd Service Example

Create `/etc/systemd/system/vllm-chatbot.service`:

```ini
[Unit]
Description=vLLM Chatbot Service
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/ai-chatbot-vllm
ExecStart=/path/to/ai-chatbot-vllm/start_all.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable vllm-chatbot.service
sudo systemctl start vllm-chatbot.service
```

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [vLLM](https://vllm.ai) - Fast LLM inference engine
- [LangChain](https://langchain.com) - LLM application framework
- [Streamlit](https://streamlit.io) - Rapid web app development
- [Mistral AI](https://mistral.ai) - Mistral 7B model
