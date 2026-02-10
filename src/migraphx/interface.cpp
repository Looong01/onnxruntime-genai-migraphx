// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// Modifications Copyright(C) 2026 Advanced Micro Devices, Inc. All rights reserved.

#include "../generators.h"
#include "../search.h"
#include "interface.h"
#include "../cpu/interface.h"
#include "../models/model.h"

namespace Generators {
namespace MIGraphX {

struct InterfaceImpl : DeviceInterface {
  InterfaceImpl() {
  }

  DeviceType GetType() const override { return DeviceType::MIGraphX; }

  void InitOrt(const OrtApi& /*api*/, Ort::Allocator& allocator) override {
    // Since we use the CPU interface for allocation, InitOrt should not be getting called.
    assert(false);
  }

  Ort::Allocator& GetAllocator() override {
    return GetCpuInterface()->GetAllocator();
  }

  std::shared_ptr<DeviceBuffer> AllocateBase(size_t size) override {
    return GetCpuInterface()->AllocateBase(size);
  }

  std::shared_ptr<DeviceBuffer> WrapMemoryBase(void* p, size_t size) override {
    return GetCpuInterface()->WrapMemoryBase(p, size);
  }

  std::unique_ptr<Search> CreateGreedy(const GeneratorParams& params) override { 
    return std::make_unique<GreedySearch_Cpu>(params); 
  }
  
  std::unique_ptr<Search> CreateBeam(const GeneratorParams& params) override { 
    return std::make_unique<BeamSearch_Cpu>(params); 
  }

  void Synchronize() override {}  // Nothing to do
};

}  // namespace MIGraphX

DeviceInterface* GetMIGraphXInterface() {
  static std::unique_ptr<DeviceInterface> g_device = std::make_unique<MIGraphX::InterfaceImpl>();
  return g_device.get();
}

void MIGraphX_AppendProviderOptions(OrtSessionOptions& session_options,
                                    const Generators::Config& config,
                                    const Generators::Config::ProviderOptions& provider_options) {
  if (provider_options.name != "MIGraphX") {
    throw std::runtime_error("MIGraphX_AppendProviderOptions called with provider_options.name = " + provider_options.name);
  }

  std::vector<const char*> keys, values;
  for (auto& option : provider_options.options) {
    keys.emplace_back(option.first.c_str());
    values.emplace_back(option.second.c_str());
  }

  session_options.AppendExecutionProvider(provider_options.name.c_str(), keys.data(), values.data(), keys.size());
}

}  // namespace Generators
