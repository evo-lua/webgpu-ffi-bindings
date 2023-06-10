set -e

echo Building target wgpu-native

make -C deps/gfx-rs/wgpu-native

cp deps/gfx-rs/wgpu-native/target/release/wgpu_native.dll $(pwd)
cp deps/gfx-rs/wgpu-native/ffi/webgpu-headers/webgpu.h $(pwd)/deps