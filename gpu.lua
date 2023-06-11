local ffi = require("ffi")

local webgpu = ffi.load("wgpu_native")
local glfw = ffi.load("glfw3")
local glfwExt = ffi.load("glfw3webgpu")

local gpu = {}

function gpu.load_cdefs()
	local webgpu_cdefs = require("cdefs")
	ffi.cdef(webgpu_cdefs)

	local glfw_cdefs = [[
    // Platform-specific (don't care)
    typedef void* GLFWwindow;
    typedef void* GLFWmonitor;

    int glfwInit(void);
    void glfwWindowHint(int hint, int value);
    int glfwWindowShouldClose(GLFWwindow window);
    void glfwPollEvents(void);
    void glfwDestroyWindow(GLFWwindow window);
    void glfwTerminate(void);

    GLFWwindow glfwCreateWindow(int width, int height, const char* title, GLFWmonitor monitor, GLFWwindow share);
]]
	ffi.cdef(glfw_cdefs)

	local glfw_ext_cdefs = [[
	// Custom extension
	WGPUSurface glfwGetWGPUSurface(WGPUInstance instance, GLFWwindow* window);
]]
	ffi.cdef(glfw_ext_cdefs)
end

function gpu.initialize_webgpu_context()
	local desc = ffi.new("WGPUInstanceDescriptor")
	local instance = webgpu.wgpuCreateInstance(desc)
	if not instance then
		error("Could not initialize WebGPU")
	end

	return instance
end

function gpu.create_gltf_window()
	if not glfw.glfwInit() then
		error("Could not initialize GLFW")
	end

	local GLFW_CLIENT_API = 0x00022001
	local GLFW_NO_API = 0
	glfw.glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API)

	local window = glfw.glfwCreateWindow(640, 480, "Learn WebGPU", nil, nil)
	if not window then
		error("Could not open window!")
	end

	return window
end

function gpu.request_adapter_for_window_surface(instance, window)
	local surface = glfwExt.glfwGetWGPUSurface(instance, window)

	local adapterOpts = ffi.new("WGPURequestAdapterOptions")
	adapterOpts.compatibleSurface = surface

	local requestedAdapter
	local function onAdapterRequested(status, adapter, message, userdata)
		gpu.ADAPTER_REQUEST_FINISHED(status, adapter, message, userdata)
		assert(status == webgpu.WGPURequestAdapterStatus_Success, "Failed to request adapter")
		requestedAdapter = adapter
	end
	webgpu.wgpuInstanceRequestAdapter(instance, adapterOpts, onAdapterRequested, nil)

	-- The callback is always triggered before wgpuInstanceRequestAdapter returns?
	-- Source: https://eliemichel.github.io/LearnWebGPU/getting-started/the-adapter.html
	-- TBD: Why does it use a callback, then? Will this behavior change in the future?
	assert(requestedAdapter, "onAdapterRequested did not trigger, but it should have") -- Better safe than sorry
	return requestedAdapter
end

function gpu.inspect_adapter(adapter)
	local featureCount = webgpu.wgpuAdapterEnumerateFeatures(adapter, nil)
	local features = ffi.new("WGPUFeatureName[?]", featureCount)
	webgpu.wgpuAdapterEnumerateFeatures(adapter, features)

	print("Adapter features:")
	for index = 0, tonumber(featureCount) - 1 do
		local feature = features[index]
		print(index + 1, feature)
	end

	local limits = ffi.new("WGPUSupportedLimits")
	local success = webgpu.wgpuAdapterGetLimits(adapter, limits)
	if not success then
		error("Failed to get adapter limits")
	end

	print("Adapter limits:")
	print("\tmaxTextureDimension1D: ", limits.limits.maxTextureDimension1D)
	print("\tmaxTextureDimension2D: ", limits.limits.maxTextureDimension2D)
	print("\tmaxTextureDimension3D: ", limits.limits.maxTextureDimension3D)
	print("\tmaxTextureArrayLayers: ", limits.limits.maxTextureArrayLayers)
	print("\tmaxBindGroups: ", limits.limits.maxBindGroups)
	print("\tmaxDynamicUniformBuffersPerPipelineLayout: ", limits.limits.maxDynamicUniformBuffersPerPipelineLayout)
	print("\tmaxDynamicStorageBuffersPerPipelineLayout: ", limits.limits.maxDynamicStorageBuffersPerPipelineLayout)
	print("\tmaxSampledTexturesPerShaderStage: ", limits.limits.maxSampledTexturesPerShaderStage)
	print("\tmaxSamplersPerShaderStage: ", limits.limits.maxSamplersPerShaderStage)
	print("\tmaxStorageBuffersPerShaderStage: ", limits.limits.maxStorageBuffersPerShaderStage)
	print("\tmaxStorageTexturesPerShaderStage: ", limits.limits.maxStorageTexturesPerShaderStage)
	print("\tmaxUniformBuffersPerShaderStage: ", limits.limits.maxUniformBuffersPerShaderStage)
	print("\tmaxUniformBufferBindingSize: ", limits.limits.maxUniformBufferBindingSize)
	print("\tmaxStorageBufferBindingSize: ", limits.limits.maxStorageBufferBindingSize)
	print("\tminUniformBufferOffsetAlignment: ", limits.limits.minUniformBufferOffsetAlignment)
	print("\tminStorageBufferOffsetAlignment: ", limits.limits.minStorageBufferOffsetAlignment)
	print("\tmaxVertexBuffers: ", limits.limits.maxVertexBuffers)
	print("\tmaxVertexAttributes: ", limits.limits.maxVertexAttributes)
	print("\tmaxVertexBufferArrayStride: ", limits.limits.maxVertexBufferArrayStride)
	print("\tmaxInterStageShaderComponents: ", limits.limits.maxInterStageShaderComponents)
	print("\tmaxComputeWorkgroupStorageSize: ", limits.limits.maxComputeWorkgroupStorageSize)
	print("\tmaxComputeInvocationsPerWorkgroup: ", limits.limits.maxComputeInvocationsPerWorkgroup)
	print("\tmaxComputeWorkgroupSizeX: ", limits.limits.maxComputeWorkgroupSizeX)
	print("\tmaxComputeWorkgroupSizeY: ", limits.limits.maxComputeWorkgroupSizeY)
	print("\tmaxComputeWorkgroupSizeZ: ", limits.limits.maxComputeWorkgroupSizeZ)
	print("\tmaxComputeWorkgroupsPerDimension: ", limits.limits.maxComputeWorkgroupsPerDimension)

	local properties = ffi.new("WGPUAdapterProperties")
	webgpu.wgpuAdapterGetProperties(adapter, properties)
	print("Adapter properties:")
	print("\tvendorID: ", properties.vendorID)
	print("\tdeviceID: ", properties.deviceID)
	print("\tname: ", properties.name)
	if properties.driverDescription then
		print("\tdriverDescription: ", properties.driverDescription)
	end
	print("\tadapterType: ", properties.adapterType)
	print("\tbackendType: ", properties.backendType)
end

-- This should work with LuaJIT/PUC Lua only
function gpu.run_ui_loop_with_glfw(window)
	while glfw.glfwWindowShouldClose(window) == 0 do
		glfw.glfwPollEvents()
	end
end

-- This only works if using evo, luvit, or the luv bindings manually
function gpu.run_ui_loop_with_libuv(window)
	local uv = require("uv")
	local timer = uv.new_timer()
	local updateTimeInMilliseconds = 16
	timer:start(0, updateTimeInMilliseconds, function()
		glfw.glfwPollEvents()
		if glfw.glfwWindowShouldClose(window) ~= 0 then
			timer:stop()
			uv.stop()
		end
	end)
end

-- Placeholder event handler; can be overridden as needed
function gpu.ADAPTER_REQUEST_FINISHED(status, adapter, message, userdata)
	print("ADAPTER_REQUEST_FINISHED", status, adapter, message, userdata)
end

gpu.load_cdefs()

return gpu
