set -e

echo Building target wgpu-native

make -C deps/gfx-rs/wgpu-native lib-native

cp deps/gfx-rs/wgpu-native/target/release/wgpu_native.dll $(pwd)
cp deps/gfx-rs/wgpu-native/ffi/webgpu-headers/webgpu.h $(pwd)/deps

echo Building target glfw3webgpu

cmake -S . -B cmakebuild-windows -DBUILD_SHARED_LIBS=ON
cmake --build cmakebuild-windows

cp cmakebuild-windows/libglfw3webgpu.dll $(pwd)/glfw3webgpu.dll
cp cmakebuild-windows/deps/gfx-rs/wgpu-native/examples/vendor/glfw/src/glfw3.dll $(pwd)
