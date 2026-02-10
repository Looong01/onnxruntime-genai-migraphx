# MIGraphX Backend Example

This example demonstrates how to use ONNX Runtime GenAI with AMD's MIGraphX backend for inference on AMD GPUs.

## Prerequisites

1. **AMD GPU with ROCm support** (e.g., MI100, MI200, MI300 series, or Radeon RX 6000/7000 series)
2. **ROCm installed** (version 5.7 or later)
3. **ONNX Runtime GenAI built with MIGraphX support**

## Installation

Follow the [MIGraphX build guide](../../docs/how-to-build-migraphx.md) to build ONNX Runtime GenAI with MIGraphX backend support.

## Model Configuration

Your model directory should contain a `genai_config.json` file with MIGraphX provider configuration. See `genai_config_migraphx_example.json` for a sample configuration.

Key configuration options for MIGraphX:

```json
{
  "model": {
    "decoder": {
      "session_options": {
        "provider_options": [
          {
            "name": "MIGraphX",
            "options": {
              "device_id": "0",          // GPU device ID
              "fp16_enable": "1",         // Enable FP16 inference
              "int8_enable": "0",         // Enable INT8 inference
              "exhaustive_tune": "0"      // Enable exhaustive tuning
            }
          }
        ]
      }
    }
  }
}
```

## Running the Example

```bash
# Basic usage
python migraphx_example.py

# Or use the standard examples with MIGraphX
python model-chat.py -m /path/to/model -e migraphx
python model-qa.py -m /path/to/model -e migraphx
python model-generate.py -m /path/to/model -e migraphx
```

## MIGraphX Provider Options

| Option | Description | Default | Values |
|--------|-------------|---------|--------|
| `device_id` | GPU device ID to use | "0" | "0", "1", etc. |
| `fp16_enable` | Enable FP16 precision | "0" | "0" (disabled), "1" (enabled) |
| `int8_enable` | Enable INT8 precision | "0" | "0" (disabled), "1" (enabled) |
| `exhaustive_tune` | Enable exhaustive tuning for optimal performance | "0" | "0" (disabled), "1" (enabled) |

## Performance Tips

1. **Enable FP16**: Set `"fp16_enable": "1"` for faster inference on supported GPUs
2. **Exhaustive Tuning**: Set `"exhaustive_tune": "1"` to find optimal kernels (increases first-run time but improves subsequent runs)
3. **Check GPU Utilization**: Use `rocm-smi` to monitor GPU usage
4. **Batch Size**: Adjust batch size based on your GPU memory

## Troubleshooting

### MIGraphX provider not found
Ensure ONNX Runtime was built with MIGraphX support. Check the build output for MIGraphX-related messages.

### Out of memory errors
- Reduce batch size in generation parameters
- Enable FP16 to reduce memory usage
- Use a smaller model

### Slow first run
MIGraphX optimizes kernels on first run. Use `"exhaustive_tune": "1"` to cache optimized kernels.

### Check GPU availability
```bash
# List available GPUs
rocm-smi

# Check ROCm installation
rocminfo

# Verify GPU is visible to the system
ls -la /dev/kfd /dev/dri
```

## Additional Resources

- [Main Build Documentation](../../docs/how-to-build-migraphx.md)
- [MIGraphX GitHub](https://github.com/ROCm/AMDMIGraphX)
- [ROCm Documentation](https://rocm.docs.amd.com/)
- [ONNX Runtime GenAI Documentation](https://onnxruntime.ai/docs/genai)
