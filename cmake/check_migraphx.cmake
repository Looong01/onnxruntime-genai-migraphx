if(USE_MIGRAPHX AND NOT EXISTS "${ORT_LIB_DIR}/${ONNXRUNTIME_PROVIDERS_MIGRAPHX_LIB}")
  message(FATAL_ERROR "Expected the ONNX Runtime providers MIGraphX library to be found at ${ORT_LIB_DIR}/${ONNXRUNTIME_PROVIDERS_MIGRAPHX_LIB}. Actual: Not found.")
endif()

if(USE_MIGRAPHX)
  add_compile_definitions(USE_MIGRAPHX=1)
else()
  add_compile_definitions(USE_MIGRAPHX=0)
endif()
