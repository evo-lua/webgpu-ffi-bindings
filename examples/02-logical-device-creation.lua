-- Based on https://eliemichel.github.io/LearnWebGPU/getting-started/the-device.html
local gpu = require("gpu")

local context = gpu.initialize_webgpu_context()
local window = gpu.create_gltf_window()
local adapter = gpu.request_adapter_for_window_surface(context, window)

-- Lua mapping of the fields contained in WGPUDeviceDescriptor (for ease of use)
local options = {
	label = "My very own WebGPU device",
	-- Leave fields empty (or omit the options parameter entirely) to use default options
}
local deviceInfo = gpu.request_device_for_adapter(adapter, options)

assert(deviceInfo.device, "Failed to create logical WebGPU device")
assert(deviceInfo.descriptor, "Failed to create device descriptor for the provided creation options")

print("Successfully created WebGPU device: " .. deviceInfo.options.label)
