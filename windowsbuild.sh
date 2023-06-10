set -e

# Prebuilt wgpu DLL was built with MSVC, cannot link with gcc/clang (TODO fix this, but the build instructions are incomplete)
cmake -S . -B cmakebuild-windows -G "Visual Studio 17 2022" -DBUILD_SHARED_LIBS=ON
cmake --build cmakebuild-windows  --verbose