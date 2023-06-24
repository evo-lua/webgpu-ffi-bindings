# WebGPU Bindings for LuaJIT

LuaJIT FFI bindings for the [WebGPU](https://en.wikipedia.org/wiki/WebGPU) implementations from Mozilla ([webgpu-native](https://github.com/webgpu-native)) and Google ([dawn](https://dawn.googlesource.com/dawn))

Note: Despite the name, WebGPU does not involve browsers or JavaScript. It's a 3D API abstraction with its own [spec](https://www.w3.org/TR/webgpu/).

## What can I do with it?

Submit work to your GPU, from Lua. In a way that's completely cross-platform and that doesn't require using [OpenGL](https://en.wikipedia.org/wiki/OpenGL).

## Why would anyone want to do that?

WebGPU is somewhat more usable (by mere mortals) than most of the modern "low-level" graphics APIs, and Lua is arguably less annoying to work with than C/C++ or JavaScript/TypeScript. That's just my personal opinion, of course, but I see quite some potential in the idea of combining both, which is why I wanted to explore it further. This might not be a good idea at all, but there's really no telling until you've tried! And that's what this repository is for.

## Why use WebGPU and not DX12/Vulkan/Metal?

Using WebGPU over OpenGL or Vulkan/Metal/DirectX12 has many advantages. [Some people](https://cohost.org/mcc/post/1406157-i-want-to-talk-about-webgpu) believe it's "the future".

While I don't know about that, I do know a few things:

* DirectX is Microsoft-proprietary and doesn't work on other platforms
* Metal is Apple-proprietary and doesn't work on other platforms
* Vulkan doesn't work on many platforms (and its design is... contentious)
* WebGPU has major industry buyin and is definitely a step up from OpenGL

All in all, targeting WebGPU as a backend certainly seems better than writing low-level rendering code multiple times.

## Goals

For now, I mainly seek to answer a few key questions to determine whether this is even a viable approach:

- Determine feasibility: Evaluate performance and maintainability in the face of upstream changes
- Cross-platform support: Investigate functionality and performance on MSVC, MSYS2, OSX, and Linux
- Backend-agnostic: Test whether it works using either the Firefox or the Chrome implementation

If all goes well I might build some more high-level abstractions on top to make it easy to use (details are TBD).

## Status

Prototype, proof of concept, or whatever you want to call "I had this crazy idea and I want to try out if it works".

**UPDATE:** Development here is currently halted as I've moved WebGPU support into the runtime itself. This may change in the future.

## Roadmap

- [x] Auto-generate FFI bindings from the WebGPU C API headers
- [x] Initial testing using Mozilla's `webgpu-native` backend on Windows
- [ ] Extend testing to native Linux and OSX platforms
- [ ] Add some examples to test different (basic) rendering scenarios
- [ ] Performance evaluation of the FFI bindings in the above scenarios
- [ ] Optionally support `dawn` as an alternative backend
- [ ] Optionally publish prebuilt releases of the examples/dependencies (GLFW and WebGPU extensions)
- [ ] Add some better documentation to replace the rather basic README file
