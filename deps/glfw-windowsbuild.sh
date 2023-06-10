set -e

echo Building target glfw

cmake -S deps/gfx-rs/wgpu-native/examples/vendor/glfw -B cmakebuild-windows -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF
cmake --build cmakebuild-windows

cp cmakebuild-windows/src/glfw3.dll $(pwd)