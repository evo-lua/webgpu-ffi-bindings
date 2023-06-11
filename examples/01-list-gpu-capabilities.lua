-- Based on https://eliemichel.github.io/LearnWebGPU/getting-started/the-adapter.html
local gpu = require("gpu")

local context = gpu.initialize_webgpu_context()
local window = gpu.create_gltf_window()
local adapter = gpu.request_adapter_for_window_surface(context, window)

-- No need to start a UI loop here, though there's no reason why you couldn't
gpu.inspect_adapter(adapter)
