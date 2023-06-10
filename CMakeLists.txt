cmake_minimum_required(VERSION 3.1...3.25)

# Required for wbgpu?
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

project(
	LearnWebGPU
	VERSION 0.1.0
	LANGUAGES CXX C
)

# include(utils.cmake)

add_subdirectory(deps/glfw)

# Include webgpu directory, to define the 'webgpu' target
# add_subdirectory(deps/webgpu-native)

add_executable(App
	deps/glfw3webgpu.c
	main.cpp
)

target_include_directories(App PRIVATE
	deps
	deps/webgpu-native
)

# Full path to the .lib file
set(WEBGPU_NATIVE_LIBRARY "${CMAKE_SOURCE_DIR}/deps/webgpu-native/wgpu_native.lib")

# Link against the library
target_link_libraries(App PRIVATE glfw ${WEBGPU_NATIVE_LIBRARY} d3dcompiler Ws2_32 bcrypt userenv)


set_target_properties(App PROPERTIES CXX_STANDARD 20)
# target_treat_all_warnings_as_errors(App)

# The application's binary must find wgpu.dll or libwgpu.so at runtime,
# so we automatically copy it (it's called WGPU_RUNTIME_LIB in general)
# next to the binary.
# target_copy_webgpu_binaries(App)

add_library(glfw3webgpu SHARED)
target_sources(glfw3webgpu PRIVATE "${CMAKE_SOURCE_DIR}/deps/glfw3webgpu.c")
target_include_directories(glfw3webgpu PRIVATE
	deps
	deps/glfw/include
	deps/webgpu-native
)
target_link_libraries(glfw3webgpu PRIVATE glfw ${WEBGPU_NATIVE_LIBRARY} d3dcompiler Ws2_32 bcrypt userenv)
target_compile_definitions(glfw3webgpu PRIVATE BUILD_SHARED_GLFW_EXTENSIONS)
