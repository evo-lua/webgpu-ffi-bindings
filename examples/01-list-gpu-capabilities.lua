-- See https://eliemichel.github.io/LearnWebGPU/getting-started/the-adapter.html

local cdefs = require("cdefs")
local ffi = require("ffi")

ffi.cdef(cdefs)
ffi.load("wgpu_native")

local webgpu = ffi.load("wgpu_native")

local desc = ffi.new("WGPUInstanceDescriptor")
local instance = webgpu.wgpuCreateInstance(desc)
if not instance then
	error("Could not initialize WebGPU!")
end

print("Requesting adapter...")
local adapterOpts = ffi.new("WGPURequestAdapterOptions")

local requestedAdapter
local function onAdapterRequested(status, adapter, message, pUserData)
	print("onAdapterRequested", status, adapter, message, pUserData)
	assert(status == webgpu.WGPURequestAdapterStatus_Success, "Failed to request adapter")
	requestedAdapter = adapter
end
webgpu.wgpuInstanceRequestAdapter(instance, adapterOpts, onAdapterRequested, nil)
print("Got adapter: ", requestedAdapter)

local function inspectAdapter(adapter)
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
	print("\tname: ", ffi.string(properties.name))
	if properties.driverDescription then
		print("\tdriverDescription: ", ffi.string(properties.driverDescription))
	end
	print("\tadapterType: ", properties.adapterType)
	print("\tbackendType: ", properties.backendType)
end

inspectAdapter(requestedAdapter)
