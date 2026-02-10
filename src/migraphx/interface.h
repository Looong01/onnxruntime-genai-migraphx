// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
//
// Modifications Copyright(C) 2026 Advanced Micro Devices, Inc. All rights reserved.
#pragma once

#include "../config.h"

namespace Generators {

DeviceInterface* GetMIGraphXInterface();

void MIGraphX_AppendProviderOptions(OrtSessionOptions& session_options,
                                    const Generators::Config& config,
                                    const Generators::Config::ProviderOptions& provider_options);

}  // namespace Generators
