# Shadertoy Shader Folder

Files in this folder are loaded directly at runtime and hot reloaded when they change.
In a portable build, this folder lives next to the executable.

- Use `.toy` or `.glsl` files that define `mainImage(out vec4 fragColor, in vec2 fragCoord)`.
- The game wraps your file so you can use Shadertoy-style uniforms such as `iTime`, `iResolution`, and `iChannel0`.
- `fragCoord` uses the current cube face as a local surface instead of the whole window.
- Helper functions such as `getLocalCenteredPosition()` and `getWorldPosition()` are available in the wrapper.
