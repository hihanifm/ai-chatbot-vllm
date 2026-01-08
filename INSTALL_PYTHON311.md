# Installing Python 3.11 on Linux

## Ubuntu / Debian

### Method 1: Using apt (Ubuntu 22.04+)
```bash
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev
```

### Method 2: Using deadsnakes PPA (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev
```

### Verify Installation
```bash
python3.11 --version
# Should output: Python 3.11.x
```

## Fedora / RHEL / CentOS

```bash
sudo dnf install python3.11 python3.11-pip
```

Or on older systems:
```bash
sudo yum install python3.11 python3.11-pip
```

## Arch Linux

```bash
sudo pacman -S python311
```

## openSUSE

```bash
sudo zypper install python311 python311-pip
```

## Generic / Compile from Source

If your distribution doesn't have Python 3.11 in repositories:

```bash
# Install build dependencies
sudo apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev

# Download Python 3.11 source
cd /tmp
wget https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz
tar -xf Python-3.11.9.tgz
cd Python-3.11.9

# Configure and compile
./configure --enable-optimizations --prefix=/usr/local
make -j$(nproc)
sudo make altinstall  # Use altinstall to avoid replacing system python3

# Verify
/usr/local/bin/python3.11 --version
```

## After Installation

Once Python 3.11 is installed, create your virtual environment:

```bash
cd /path/to/ai-chatbot-vllm
rm -rf .venv  # Remove old venv if exists
python3.11 -m venv .venv
./setup.sh
```

## Troubleshooting

**If python3.11 command not found:**
- Make sure it's installed: `which python3.11`
- Check installation path: `/usr/bin/python3.11` or `/usr/local/bin/python3.11`
- Use full path if needed: `/usr/bin/python3.11 -m venv .venv`

**For Ubuntu/Debian users:**
- You may need to install `python3.11-distutils` if venv module is missing:
  ```bash
  sudo apt install python3.11-distutils
  ```
