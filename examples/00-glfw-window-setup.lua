-- This just sets up a native window with a WebGPU-compatible surface to draw on
local gpu = require("gpu")

print("Setting up a new WebGPU context ...")
local context = gpu.initialize_webgpu_context()
local window = gpu.create_gltf_window()
local adapter = gpu.request_adapter_for_window_surface(context, window)

assert(adapter, "Failed to create a GPU adapter for the given window's backing store")

-- Can now run the GLFW UI loop, either manually or with a polling timer (requires libuv)
local success, uv = pcall(require, "uv")
local isAsyncRuntime = success and (type(uv) == "table")
if isAsyncRuntime then
	print("Starting UI loop with a polling timer (non-blocking) ...")
	gpu.run_ui_loop_with_libuv(window)
else
	print("Starting UI loop with GLFW (blocking) ...")
	gpu.run_ui_loop_with_glfw(window)
end
