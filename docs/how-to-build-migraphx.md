# Building ONNX Runtime GenAI with MIGraphX Backend

This guide provides detailed instructions for building ONNX Runtime GenAI with MIGraphX backend support on AMD GPUs.

## Overview

MIGraphX is AMD's graph inference engine that accelerates machine learning models on AMD GPUs. It is an execution provider for ONNX Runtime that enables high-performance inference on AMD hardware.

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04/22.04 or RHEL 8/9 recommended)
- **Hardware**: AMD GPU with ROCm support (e.g., MI100, MI200, MI300 series, or Radeon RX 6000/7000 series)
- **GPU Driver**: AMD GPU driver compatible with your GPU
- **ROCm**: ROCm 5.7 or later

### Software Dependencies

1. **ROCm Installation**
   
   Follow the official AMD ROCm installation guide: https://rocm.docs.amd.com/
   
   For Ubuntu 22.04:
   ```bash
   # Add ROCm repository
   wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
   echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.3 jammy main" | sudo tee /etc/apt/sources.list.d/rocm.list
   sudo apt update
   
   # Install ROCm
   sudo apt install rocm-hip-sdk rocm-libs
   
   # Add user to video and render groups
   sudo usermod -a -G video $LOGNAME
   sudo usermod -a -G render $LOGNAME
   ```

2. **CMake** (version 3.26 or later)
   ```bash
   sudo apt install cmake
   # Or download latest from https://cmake.org/download/
   ```

3. **Python** (3.8 or later)
   ```bash
   sudo apt install python3 python3-pip python3-dev
   ```

4. **Build Tools**
   ```bash
   sudo apt install build-essential git
   ```

5. **ONNX Runtime with MIGraphX Support**
   
   You need ONNX Runtime built with MIGraphX execution provider. You can either:
   - Use pre-built ONNX Runtime packages (if available)
   - Build ONNX Runtime from source with MIGraphX support

## Building from Source

### Step 1: Clone the Repository

```bash
git clone https://github.com/microsoft/onnxruntime-genai.git
cd onnxruntime-genai
```

### Step 2: Option A - Using Pre-built ONNX Runtime

If you have pre-built ONNX Runtime binaries with MIGraphX support:

```bash
# Set the path to your ONNX Runtime installation
export ORT_HOME=/path/to/onnxruntime

# Build ONNX Runtime GenAI with MIGraphX support
python build.py --use_migraphx --config Release
```

### Step 2: Option B - Auto-download ONNX Runtime (Recommended for Development)

The build script can automatically download a compatible ONNX Runtime build:

```bash
# Build with auto-download
python build.py --use_migraphx --config Release
```

Note: The build system will attempt to download ONNX Runtime ROCm package which includes MIGraphX support.

### Step 3: Build Python Wheel (Optional)

To build the Python package:

```bash
python build.py --use_migraphx --config Release
```

The wheel file will be created in `build/[platform]/wheel/` directory.

### Step 4: Install Python Package

```bash
pip install build/Linux/wheel/onnxruntime_genai-*-linux_x86_64.whl
```

## Build Options

The following CMake options are available for MIGraphX builds:

| Option | Default | Description |
|--------|---------|-------------|
| `USE_MIGRAPHX` | OFF | Enable MIGraphX backend support |
| `ORT_HOME` | - | Path to pre-built ONNX Runtime installation |

### Advanced Build Examples

**Build with custom ONNX Runtime path:**
```bash
python build.py --use_migraphx --config Release --ort_home /path/to/onnxruntime
```

**Build with Java bindings:**
```bash
python build.py --use_migraphx --config Release --build_java
```

**Debug build:**
```bash
python build.py --use_migraphx --config Debug
```

**Build with tests enabled:**
```bash
python build.py --use_migraphx --config Release --enable_tests
```

## Using CMake Directly

For more control over the build process, you can use CMake directly:

```bash
mkdir build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DUSE_MIGRAPHX=ON \
  -DORT_HOME=/path/to/onnxruntime \
  -DENABLE_PYTHON=ON

cmake --build . --config Release -j$(nproc)
```

## Configuration

### Model Configuration

To use MIGraphX backend with your models, add the following to your `genai_config.json`:

```json
{
  "model": {
    "decoder": {
      "session_options": {
        "provider_options": [
          {
            "name": "MIGraphX",
            "options": {
              "device_id": "0",
              "fp16_enable": "1",
              "int8_enable": "0"
            }
          }
        ]
      }
    }
  }
}
```

### Common MIGraphX Provider Options

| Option | Description | Default |
|--------|-------------|---------|
| `device_id` | GPU device ID to use | "0" |
| `fp16_enable` | Enable FP16 inference | "0" |
| `int8_enable` | Enable INT8 inference | "0" |
| `exhaustive_tune` | Enable exhaustive tuning | "0" |

## Python Example

```python
import onnxruntime_genai as og

# Load model with MIGraphX backend
model = og.Model('path/to/model')
tokenizer = og.Tokenizer(model)

# Create generator parameters
params = og.GeneratorParams(model)
params.set_search_options(max_length=100)

# Generate text
input_tokens = tokenizer.encode("Hello, world!")
generator = og.Generator(model, params)
generator.append_tokens(input_tokens)

while not generator.is_done():
    generator.generate_next_token()
    
output_tokens = generator.get_sequence(0)
output_text = tokenizer.decode(output_tokens)
print(output_text)
```

## Troubleshooting

### ROCm Not Found

If CMake cannot find ROCm, set the ROCm path:
```bash
export ROCM_PATH=/opt/rocm
export CMAKE_PREFIX_PATH=$ROCM_PATH:$CMAKE_PREFIX_PATH
```

### GPU Not Detected

Verify your GPU is visible to ROCm:
```bash
rocm-smi
rocminfo
```

### Build Errors

1. **Missing ROCm libraries**: Ensure all ROCm components are installed
2. **ONNX Runtime not found**: Verify ORT_HOME points to a valid ONNX Runtime installation with MIGraphX provider
3. **CMake version**: Ensure CMake 3.26 or later is installed

### Runtime Errors

1. **Provider not available**: Ensure ONNX Runtime was built with MIGraphX support
2. **Out of memory**: Reduce batch size or model size
3. **Device not found**: Check device_id in provider options matches your GPU

## Performance Tuning

### FP16 Inference

Enable FP16 for better performance on supported GPUs:

```json
{
  "name": "MIGraphX",
  "options": {
    "fp16_enable": "1"
  }
}
```

### Tuning

Enable exhaustive tuning for optimal performance (increases initial load time):

```json
{
  "name": "MIGraphX",
  "options": {
    "exhaustive_tune": "1"
  }
}
```

## Supported Models

MIGraphX backend supports the same model architectures as other ONNX Runtime GenAI backends:

- LLaMA and variants (LLaMA 2, LLaMA 3, etc.)
- Phi models (Phi-2, Phi-3, etc.)
- Mistral and Mixtral
- GPT models
- Qwen models
- And more (see main README for full list)

## Known Limitations

1. MIGraphX is primarily supported on Linux
2. Windows support may be limited
3. Some advanced features may require specific ROCm versions

## Additional Resources

- [ONNX Runtime Documentation](https://onnxruntime.ai/)
- [ROCm Documentation](https://rocm.docs.amd.com/)
- [MIGraphX GitHub](https://github.com/ROCm/AMDMIGraphX)
- [ONNX Runtime GenAI Examples](../examples/)

## Contributing

If you encounter issues or have suggestions for improving MIGraphX support, please open an issue on the GitHub repository.
