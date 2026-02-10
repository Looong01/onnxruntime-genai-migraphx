#!/bin/bash
# Verification script for MIGraphX backend implementation

echo "========================================"
echo "MIGraphX Backend Implementation Verification"
echo "========================================"
echo ""

# Check if source files exist
echo "1. Checking source files..."
files_to_check=(
    "src/migraphx/interface.h"
    "src/migraphx/interface.cpp"
    "cmake/check_migraphx.cmake"
    "docs/how-to-build-migraphx.md"
    "docs/migraphx-support-summary-zh.md"
    "examples/python/migraphx_example.py"
    "examples/python/genai_config_migraphx_example.json"
    "examples/python/README_MIGRAPHX.md"
)

all_exist=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✓ $file"
    else
        echo "   ✗ $file (missing)"
        all_exist=false
    fi
done
echo ""

# Check if MIGraphX is mentioned in key files
echo "2. Checking integration in key files..."

check_pattern() {
    local file=$1
    local pattern=$2
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "   ✓ $file contains '$pattern'"
        return 0
    else
        echo "   ✗ $file missing '$pattern'"
        return 1
    fi
}

check_pattern "src/smartptrs.h" "MIGraphX"
check_pattern "src/generators.cpp" "migraphx/interface.h"
check_pattern "src/generators.cpp" "GetMIGraphXInterface"
check_pattern "src/models/model.cpp" "MIGraphX"
check_pattern "cmake/options.cmake" "USE_MIGRAPHX"
check_pattern "cmake/global_variables.cmake" "ONNXRUNTIME_PROVIDERS_MIGRAPHX_LIB"
check_pattern "build.py" "--use_migraphx"
check_pattern "README.md" "MIGraphX"
echo ""

# Check Python syntax
echo "3. Checking Python file syntax..."
if command -v python3 &> /dev/null; then
    python3 -m py_compile examples/python/migraphx_example.py 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ migraphx_example.py syntax is valid"
    else
        echo "   ✗ migraphx_example.py has syntax errors"
    fi
    
    python3 -m py_compile build.py 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ build.py syntax is valid"
    else
        echo "   ✗ build.py has syntax errors"
    fi
else
    echo "   ⚠ Python3 not found, skipping syntax check"
fi
echo ""

# Check JSON syntax
echo "4. Checking JSON file syntax..."
if command -v python3 &> /dev/null; then
    python3 -c "import json; json.load(open('examples/python/genai_config_migraphx_example.json'))" 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✓ genai_config_migraphx_example.json is valid JSON"
    else
        echo "   ✗ genai_config_migraphx_example.json has JSON syntax errors"
    fi
else
    echo "   ⚠ Python3 not found, skipping JSON check"
fi
echo ""

# Check build.py help
echo "5. Checking build script integration..."
if python3 build.py --help | grep -q "use_migraphx"; then
    echo "   ✓ --use_migraphx flag is available in build.py"
else
    echo "   ✗ --use_migraphx flag not found in build.py"
fi
echo ""

# Summary
echo "========================================"
echo "Verification Summary"
echo "========================================"
echo ""
echo "MIGraphX backend implementation includes:"
echo "  • Core C++ interface implementation"
echo "  • CMake build system integration"
echo "  • Python build script support"
echo "  • Comprehensive documentation (English + Chinese)"
echo "  • Usage examples and configuration templates"
echo ""
echo "To build with MIGraphX support:"
echo "  python build.py --use_migraphx --config Release"
echo ""
echo "For detailed instructions, see:"
echo "  • docs/how-to-build-migraphx.md (English)"
echo "  • docs/migraphx-support-summary-zh.md (中文)"
echo ""
echo "========================================"
