# ONNX Runtime GenAI 添加 MIGraphX 后端支持 - 完整指南

## 概述

本项目已成功为 ONNX Runtime GenAI 添加了 AMD MIGraphX 后端支持。MIGraphX 是 AMD 的图推理引擎，可在 AMD GPU 上加速机器学习模型推理。

## 完成的工作

### 1. 核心实现

#### 设备类型枚举 (src/smartptrs.h)
- 在 `DeviceType` 枚举中添加了 `MIGraphX`

#### MIGraphX 接口实现 (src/migraphx/)
创建了以下文件：
- **interface.h**: 声明 MIGraphX 接口函数
- **interface.cpp**: 实现 `DeviceInterface` 接口
  - 内存分配使用 CPU 接口（与 OpenVINO 类似）
  - 实现 Greedy 和 Beam 搜索
  - 提供 `MIGraphX_AppendProviderOptions` 函数用于配置提供程序选项

#### 生成器更新 (src/generators.cpp)
- 添加 MIGraphX 头文件包含
- 在 `GetDeviceInterface()` 中添加 MIGraphX 分支
- 在 `to_string()` 中添加 MIGraphX 类型转换

#### 模型配置 (src/models/model.cpp)
- 添加 MIGraphX 提供程序选项处理
- 集成 `MIGraphX_AppendProviderOptions` 函数

### 2. 构建系统集成

#### CMake 配置
- **cmake/options.cmake**: 添加 `USE_MIGRAPHX` 选项（默认 OFF）
- **cmake/check_migraphx.cmake**: 创建 MIGraphX 检查脚本
- **cmake/global_variables.cmake**: 添加 MIGraphX 源文件和库名称
- **cmake/ortlib.cmake**: 配置 MIGraphX 使用 ROCm 包
- **CMakeLists.txt**: 包含 MIGraphX 检查

#### Python 构建脚本 (build.py)
- 添加 `--use_migraphx` 命令行参数
- 更新 CMake 配置传递
- 更新依赖下载逻辑

#### 依赖管理 (tools/python/util/dependency_resolver.py)
- 更新 `download_dependencies()` 函数接受 MIGraphX 参数
- 配置 MIGraphX 使用 ROCm ONNX Runtime 包

### 3. 文档和示例

#### 构建指南 (docs/how-to-build-migraphx.md)
详细的中英文构建文档，包括：
- 系统要求（AMD GPU、ROCm 等）
- 软件依赖安装步骤
- 详细构建说明（使用预构建包或自动下载）
- CMake 直接构建方法
- 模型配置示例
- 常见问题排查
- 性能调优建议

#### Python 示例
- **examples/python/migraphx_example.py**: 完整的 Python 使用示例
- **examples/python/genai_config_migraphx_example.json**: 示例配置文件
- **examples/python/README_MIGRAPHX.md**: MIGraphX 示例专用 README

#### 主 README 更新
- 在硬件加速表中添加 MIGraphX
- 将 "AMD GPU" 移动到 "正在开发" 列（ROCm 支持）

## 使用方法

### 1. 构建

```bash
# 基本构建
python build.py --use_migraphx --config Release

# 使用自定义 ONNX Runtime 路径
python build.py --use_migraphx --config Release --ort_home /path/to/onnxruntime

# 构建 Python wheel
python build.py --use_migraphx --config Release
pip install build/Linux/wheel/onnxruntime_genai-*.whl
```

### 2. 模型配置

在模型的 `genai_config.json` 中添加：

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
              "int8_enable": "0",
              "exhaustive_tune": "0"
            }
          }
        ]
      }
    }
  }
}
```

### 3. Python 代码示例

```python
import onnxruntime_genai as og

# 加载模型（自动使用 MIGraphX 后端）
model = og.Model('path/to/model')
tokenizer = og.Tokenizer(model)

# 生成参数
params = og.GeneratorParams(model)
params.set_search_options(max_length=2048)

# 编码输入
input_tokens = tokenizer.encode("Hello, world!")

# 生成输出
generator = og.Generator(model, params)
generator.append_tokens(input_tokens)

while not generator.is_done():
    generator.generate_next_token()
    
output_tokens = generator.get_sequence(0)
output_text = tokenizer.decode(output_tokens)
print(output_text)
```

## MIGraphX 提供程序选项

| 选项 | 说明 | 默认值 | 可选值 |
|-----|------|--------|--------|
| `device_id` | 使用的 GPU 设备 ID | "0" | "0", "1" 等 |
| `fp16_enable` | 启用 FP16 推理 | "0" | "0" (禁用), "1" (启用) |
| `int8_enable` | 启用 INT8 推理 | "0" | "0" (禁用), "1" (启用) |
| `exhaustive_tune` | 启用详尽调优 | "0" | "0" (禁用), "1" (启用) |

## 系统要求

### 硬件
- AMD GPU，支持 ROCm（如 MI100、MI200、MI300 系列或 Radeon RX 6000/7000 系列）

### 软件
- Linux（推荐 Ubuntu 20.04/22.04 或 RHEL 8/9）
- ROCm 5.7 或更高版本
- CMake 3.26 或更高版本
- Python 3.8 或更高版本
- 支持 MIGraphX 的 ONNX Runtime

## 性能优化建议

1. **启用 FP16**: 在支持的 GPU 上设置 `"fp16_enable": "1"` 以获得更快的推理速度
2. **详尽调优**: 设置 `"exhaustive_tune": "1"` 以找到最佳内核（首次运行时间更长，但后续运行更快）
3. **检查 GPU 利用率**: 使用 `rocm-smi` 监控 GPU 使用情况
4. **批量大小**: 根据 GPU 内存调整批量大小

## 故障排除

### ROCm 未找到
```bash
export ROCM_PATH=/opt/rocm
export CMAKE_PREFIX_PATH=$ROCM_PATH:$CMAKE_PREFIX_PATH
```

### GPU 未检测到
```bash
rocm-smi
rocminfo
```

### 提供程序不可用
确保 ONNX Runtime 已构建 MIGraphX 支持

## 技术实现细节

### 设计模式
MIGraphX 实现遵循与 OpenVINO 和 RyzenAI 相同的模式：
- 使用 CPU 接口进行内存分配
- 实现 `DeviceInterface` 的所有必需方法
- 使用 CPU 搜索实现（Greedy 和 Beam）
- 通过 `AppendProviderOptions` 配置执行提供程序

### 依赖关系
- MIGraphX 使用 ONNX Runtime ROCm 包
- 库名称定义在 `cmake/global_variables.cmake` 中
- 检查脚本验证 MIGraphX 库的存在

### 构建流程
1. CMake 检查 `USE_MIGRAPHX` 选项
2. 如果启用，添加 `USE_MIGRAPHX=1` 编译定义
3. 包含 MIGraphX 源文件到构建中
4. 链接 MIGraphX 执行提供程序库

## 支持的模型

MIGraphX 后端支持与其他 ONNX Runtime GenAI 后端相同的模型架构：
- LLaMA 及变体（LLaMA 2、LLaMA 3 等）
- Phi 模型（Phi-2、Phi-3 等）
- Mistral 和 Mixtral
- GPT 模型
- Qwen 模型
- 更多（查看主 README 获取完整列表）

## 其他资源

- [ONNX Runtime 文档](https://onnxruntime.ai/)
- [ROCm 文档](https://rocm.docs.amd.com/)
- [MIGraphX GitHub](https://github.com/ROCm/AMDMIGraphX)
- [构建指南](docs/how-to-build-migraphx.md)
- [示例代码](examples/python/README_MIGRAPHX.md)

## 贡献

如果遇到问题或对改进 MIGraphX 支持有建议，请在 GitHub 存储库上提出 issue。

## 许可证

本项目遵循 MIT 许可证。有关详细信息，请参阅 LICENSE 文件。
