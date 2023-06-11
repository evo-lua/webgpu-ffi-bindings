-- Based on https://eliemichel.github.io/LearnWebGPU/getting-started/first-color.html
local gpu = require("gpu")

local context = gpu.initialize_webgpu_context()
local window = gpu.create_gltf_window()
local adapter = gpu.request_adapter_for_window_surface(context, window)

local deviceInfo = gpu.request_device_for_adapter(adapter)

local chain = gpu.create_swap_chain_for_window_surface(context, window, deviceInfo.device, adapter)
