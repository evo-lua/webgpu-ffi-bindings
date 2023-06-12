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
	assert(requestedAdapter, "onAdapterRequested did not trigger, but it should have")

	return requestedAdapter
end

function gpu.create_swap_chain_for_window_surface(instance, window, device, adapter)
	local surface = glfwExt.glfwGetWGPUSurface(instance, window)
	local descriptor = ffi.new("WGPUSwapChainDescriptor")
	descriptor.width = 640
	descriptor.height = 480

	local textureFormat = webgpu.wgpuSurfaceGetPreferredFormat(surface, adapter)
	descriptor.format = textureFormat
	descriptor.usage = webgpu.WGPUTextureUsage_RenderAttachment
	descriptor.presentMode = webgpu.WGPUPresentMode_Fifo

	local swapChain = webgpu.wgpuDeviceCreateSwapChain(device, surface, descriptor)
	return swapChain
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

function gpu.create_command_encoder_for_device(device)
	local descriptor = ffi.new("WGPUCommandEncoderDescriptor")
	descriptor.label = "My command encoder"

	local encoder = webgpu.wgpuDeviceCreateCommandEncoder(device, descriptor)

	webgpu.wgpuCommandEncoderInsertDebugMarker(encoder, "First debug marker")
	webgpu.wgpuCommandEncoderInsertDebugMarker(encoder, "Second debug marker")

	return encoder
end

-- TODO register only once, since there is just a single queue?
-- local function onWorkDone(status, userdata)
-- 	gpu.SUBMITTED_WORK_DONE(status, userdata)
-- end

function gpu.create_command_buffer_from_encoder(encoder)
	local descriptor = ffi.new("WGPUCommandBufferDescriptor")
	descriptor.label = "My command buffer"

	local commandBuffer = webgpu.wgpuCommandEncoderFinish(encoder, descriptor)
	return commandBuffer
end

function gpu.submit_work_to_device_queue(device, commandBuffer)
	local queue = webgpu.wgpuDeviceGetQueue(device)

	-- webgpu.wgpuQueueOnSubmittedWorkDone(queue, onWorkDone, nil) -- Exhausts FFI callback slots, needs a better approach

	-- The WebGPU API expects an array here, but we only submit a single buffer) to keep things simple)
	local commandBuffers = ffi.new("WGPUCommandBuffer[1]", commandBuffer)
	webgpu.wgpuQueueSubmit(queue, 1, commandBuffers)
end

function gpu.request_device_for_adapter(adapter, options)
	options = options or {}
	options.defaultQueue = options.defaultQueue or {}

	options.label = options.label or "Logical WebGPU Device"
	options.requiredFeaturesCount = options.requiredFeaturesCount or 0
	options.defaultQueue.label = options.defaultQueue.label or "Default Queue"

	local deviceDescriptor = ffi.new("WGPUDeviceDescriptor")
	deviceDescriptor.label = options.label
	deviceDescriptor.requiredFeaturesCount = options.requiredFeaturesCount
	deviceDescriptor.defaultQueue.label = options.defaultQueue.label

	local requestedDevice
	local function onDeviceRequested(status, device, message, userdata)
		gpu.DEVICE_REQUEST_FINISHED(status, device, message, userdata)
		assert(status == webgpu.WGPURequestDeviceStatus_Success, "Failed to request logical device")
		requestedDevice = device
	end
	webgpu.wgpuAdapterRequestDevice(adapter, deviceDescriptor, onDeviceRequested, nil)

	assert(requestedDevice, "onDeviceRequested did not trigger, but it should have")

	local deviceInfo = {
		device = requestedDevice,
		descriptor = deviceDescriptor,
		options = options,
	}

	local function onDeviceError(errorType, message, userdata)
		gpu.UNCAPTURED_DEVICE_ERROR(deviceInfo, errorType, message, userdata)
	end

	webgpu.wgpuDeviceSetUncapturedErrorCallback(requestedDevice, onDeviceError, nil)

	return deviceInfo
end

-- This should work with stock LuaJIT
function gpu.run_ui_loop_with_glfw(window, device, chain)
	while glfw.glfwWindowShouldClose(window) == 0 do
		glfw.glfwPollEvents()
		gpu.render_next_frame(device, chain)
	end
end

-- This only works if using evo, luvit, or when using the luv bindings manually
function gpu.run_ui_loop_with_libuv(window, device, chain)
	local uv = require("uv")
	local timer = uv.new_timer()
	local updateTimeInMilliseconds = 16
	timer:start(0, updateTimeInMilliseconds, function()
		glfw.glfwPollEvents()
		gpu.render_next_frame(device, chain)
		if glfw.glfwWindowShouldClose(window) ~= 0 then
			timer:stop()
			uv.stop()
		end
	end)
end

function gpu.render_next_frame(device, chain)
	if not device then
		return
	end
	if not chain then
		return
	end

	local nextTexture = webgpu.wgpuSwapChainGetCurrentTextureView(chain)
	assert(nextTexture, "Cannot acquire next swap chain texture (window surface has changed?)")

	local encoder = gpu.create_command_encoder_for_device(device)
	gpu.encode_render_pass(encoder, nextTexture)
	local commandBuffer = gpu.create_command_buffer_from_encoder(encoder)

	gpu.submit_work_to_device_queue(device, commandBuffer)

	webgpu.wgpuSwapChainPresent(chain)
end

-- Simple clear color, the most basic render pass imaginable
function gpu.encode_render_pass(encoder, nextTexture)
	-- Set up clear color using the built-in clearing mechanism of the render pass
	local renderPassColorAttachment = ffi.new("WGPURenderPassColorAttachment")
	renderPassColorAttachment.view = nextTexture
	renderPassColorAttachment.loadOp = webgpu.WGPULoadOp_Clear
	renderPassColorAttachment.storeOp = webgpu.WGPUStoreOp_Store
	renderPassColorAttachment.clearValue = ffi.new("WGPUColor", { 0.9, 0.1, 0.2, 1.0 })
	-- local attachments = ffi.new("attachment") -- An array is needed, but we only use 1 render target

	local descriptor = ffi.new("WGPURenderPassDescriptor")
	descriptor.colorAttachmentCount = 1 -- Only one render target (texture) is needed here
	descriptor.colorAttachments = renderPassColorAttachment

	descriptor.timestampWriteCount = 0 -- TBD: Do we want that?

	local renderPass = webgpu.wgpuCommandEncoderBeginRenderPass(encoder, descriptor)

	-- HACK, obviously
	if _G.TRIANGLE_RENDERING_PIPELINE then
		webgpu.wgpuRenderPassEncoderSetPipeline(renderPass, _G.TRIANGLE_RENDERING_PIPELINE) -- Select which render pipeline to use
		webgpu.wgpuRenderPassEncoderDraw(renderPass, 3, 1, 0, 0) -- Draw 1 instance of a 3-vertices shape
	end

	webgpu.wgpuRenderPassEncoderEnd(renderPass)
end

local bit = require("bit")
local binary_negation = bit.bnot

function gpu.create_triangle_render_pipeline(device, instance, window, adapter)
	local surface = glfwExt.glfwGetWGPUSurface(instance, window)
	local descriptor = ffi.new("WGPURenderPipelineDescriptor")
	local pipelineDesc = descriptor

	-- Create shader modules ("DLL for the GPU" -  here: one program with two entry points for vertex/fragment stages)
	local shaderSource = [[
		@vertex
		fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4f {
			var p = vec2f(0.0, 0.0);
			if (in_vertex_index == 0u) {
				p = vec2f(-0.5, -0.5);
			} else if (in_vertex_index == 1u) {
				p = vec2f(0.5, -0.5);
			} else {
				p = vec2f(0.0, 0.5);
			}
			return vec4f(p, 0.0, 1.0);
		}

		@fragment
		fn fs_main() -> @location(0) vec4f {
			return vec4f(0.0, 0.4, 1.0, 1.0);
		}
	]]
	-- TBD wgpu only? What?
	-- shaderDesc.hintCount = 0;
	-- shaderDesc.hints = nullptr;

	local shaderDesc = ffi.new("WGPUShaderModuleDescriptor")
	local shaderCodeDesc = ffi.new("WGPUShaderModuleWGSLDescriptor")
	-- shaderCodeDesc.chain.next = nullptr;
	shaderCodeDesc.chain.sType = webgpu.WGPUSType_ShaderModuleWGSLDescriptor
	-- Connect the chain
	shaderDesc.nextInChain = shaderCodeDesc.chain
	shaderCodeDesc.code = shaderSource -- Dawn: source ? sigh...

	local shaderModule = webgpu.wgpuDeviceCreateShaderModule(device, shaderDesc)

	-- Configure vertex processing pipeline (vertex fetch/vertex shader stages)
	pipelineDesc.vertex.bufferCount = 0
	-- pipelineDesc.vertex.buffers = nullptr;

	pipelineDesc.vertex.module = shaderModule
	pipelineDesc.vertex.entryPoint = "vs_main"
	pipelineDesc.vertex.constantCount = 0
	-- pipelineDesc.vertex.constants = nullptr;

	-- Configure primitive generation pipeline (primitive assembly/rasterization stages)
	-- Each sequence of 3 vertices is considered as a triangle
	pipelineDesc.primitive.topology = webgpu.WGPUPrimitiveTopology_TriangleList

	-- We'll see later how to specify the order in which vertices should be
	-- connected. When not specified, vertices are considered sequentially.
	pipelineDesc.primitive.stripIndexFormat = webgpu.WGPUIndexFormat_Undefined

	-- The face orientation is defined by assuming that when looking
	-- from the front of the face, its corner vertices are enumerated
	-- in the counter-clockwise (CCW) order.
	pipelineDesc.primitive.frontFace = webgpu.WGPUFrontFace_CCW

	-- But the face orientation does not matter much because we do not
	-- cull (i.e. "hide") the faces pointing away from us (which is often
	-- used for optimization).
	pipelineDesc.primitive.cullMode = webgpu.WGPUCullMode_None

	-- Configure pixel generation pipeline (fragment shader stage)
	local fragmentState = ffi.new("WGPUFragmentState")
	fragmentState.module = shaderModule
	fragmentState.entryPoint = "fs_main"
	fragmentState.constantCount = 0
	-- fragmentState.constants = nullptr;
	-- [...] We'll configure the blend stage here
	pipelineDesc.fragment = fragmentState

	-- Configure depth and stencil testing pipeline (stencil/depth stages)
	-- pipelineDesc.depthStencil = nullptr;

	-- Configure alpha blending pipeline (blending stage)
	local blendState = ffi.new("WGPUBlendState")
	local colorTarget = ffi.new("WGPUColorTargetState")
	colorTarget.format = webgpu.wgpuSurfaceGetPreferredFormat(surface, adapter)
	colorTarget.blend = blendState
	colorTarget.writeMask = webgpu.WGPUColorWriteMask_All -- We could write to only some of the color channels.

	--We have only one target because our render pass has only one output color attachment.
	fragmentState.targetCount = 1
	fragmentState.targets = colorTarget -- TBD array?

	-- pipelineDesc.fragment = fragmentState; -- TBD here?

	blendState.color.srcFactor = webgpu.WGPUBlendFactor_SrcAlpha
	blendState.color.dstFactor = webgpu.WGPUBlendFactor_OneMinusSrcAlpha
	blendState.color.operation = webgpu.WGPUBlendOperation_Add

	-- 	blendState.alpha.srcFactor = webgpu.WGPUBlendFactor_Zero
	-- blendState.alpha.dstFactor = webgpu.WGPUBlendFactor_One
	-- blendState.alpha.operation = webgpu.WGPUBlendOperation_Add

	-- Configure multisampling (here: disabled - don't map fragments to more than one sample)
	pipelineDesc.multisample.count = 1 -- Samples per pixel
	pipelineDesc.multisample.mask = binary_negation(0) -- Default value for the mask, meaning "all bits on"
	pipelineDesc.multisample.alphaToCoverageEnabled = false -- Default value as well (irrelevant for count = 1 anyways)

	-- Configure shader I/O bindings (buffers/textures - here, we omit this since they aren't yet needed)
	-- pipelineDesc.layout = nullptr

	local pipeline = webgpu.wgpuDeviceCreateRenderPipeline(device, descriptor)
	return pipeline
end

-- Placeholder event handler; can be overridden as needed
function gpu.ADAPTER_REQUEST_FINISHED(status, adapter, message, userdata)
	print("ADAPTER_REQUEST_FINISHED", status, adapter, message, userdata)
end

function gpu.DEVICE_REQUEST_FINISHED(status, device, message, userdata)
	print("DEVICE_REQUEST_FINISHED", status, device, message, userdata)
end

function gpu.UNCAPTURED_DEVICE_ERROR(deviceInfo, errorType, message, userdata)
	print("UNCAPTURED_DEVICE_ERROR", deviceInfo, errorType, message, userdata)

	local errorTypes = {
		[0] = "WGPUErrorType_NoError",
		"WGPUErrorType_Validation",
		"WGPUErrorType_OutOfMemory",
		"WGPUErrorType_Internal",
		"WGPUErrorType_Unknown",
		"WGPUErrorType_DeviceLost",
		"WGPUErrorType_Force32",
	}

	print(errorTypes[tonumber(errorType)], ffi.string(message))
end

function gpu.SUBMITTED_WORK_DONE(status, userdata)
	print("SUBMITTED_WORK_DONE", status, userdata)
end

gpu.load_cdefs()

return gpu
