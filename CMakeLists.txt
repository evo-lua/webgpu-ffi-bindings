cmake_minimum_required(VERSION 3.1...3.25)

project(
	glfw3webgpu
	VERSION 0.1.0
	LANGUAGES CXX C
)

add_library(glfw3webgpu SHARED)
target_sources(glfw3webgpu PRIVATE deps/glfw3webgpu.c)

add_subdirectory(deps/gfx-rs/wgpu-native/examples/vendor/glfw )
if(WIN32)
	set(WGPU_NATIVE_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/wgpu_native.dll)
else()
	set(WGPU_NATIVE_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/wgpu_native.so)
endif()
target_link_libraries(glfw3webgpu PUBLIC glfw ${WGPU_NATIVE_LIBRARY})

if (APPLE)
  target_compile_options(glfw3webgpu PRIVATE -x objective-c)
  target_link_libraries(glfw3webgpu PRIVATE "-framework Cocoa" "-framework CoreVideo" "-framework IOKit" "-framework QuartzCore")
endif ()

target_include_directories(glfw3webgpu PRIVATE
	deps
	deps/gfx-rs/wgpu-native/examples/vendor/glfw/include -B cmakebuild-windows
)

target_compile_definitions(glfw3webgpu PRIVATE BUILD_SHARED_LIBS)
