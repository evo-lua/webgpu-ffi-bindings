-- Based on https://eliemichel.github.io/LearnWebGPU/getting-started/the-command-queue.html
local gpu = require("gpu")

local context = gpu.initialize_webgpu_context()
local window = gpu.create_gltf_window()
local adapter = gpu.request_adapter_for_window_surface(context, window)

local deviceInfo = gpu.request_device_for_adapter(adapter)
local encoder = gpu.create_command_encoder_for_device(deviceInfo.device)
local commands = gpu.create_command_buffer_from_encoder(encoder)

gpu.submit_work_to_device_queue(deviceInfo.device, commands)
