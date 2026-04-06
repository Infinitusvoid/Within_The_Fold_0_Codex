# Editable Shader Contract

Files in this folder are loaded directly at runtime and hot reloaded when they change.

- `default_vertex.glsl` is the shared vertex shader used by every editable fragment shader.
- `*.glsl` files here are treated as full OpenGL fragment shaders.
- `../shadertoy_shaders/*.toy` files are wrapped automatically so `mainImage(out vec4, in vec2)` works in-game.
- Shadertoy-style `../shadertoy_shaders/*.glsl` files are also sanitized and rewrapped, so old `mainImage(...); main() { ... gl_FragCoord.xy; }` files stay cube-space aware.

Common fragment inputs:

- `in vec2 TexCoord`
- `in vec3 WorldPos`
- `in vec3 LocalPos`

Common uniforms:

- `sampler2D texture1`, `texture2`
- `sampler2D iChannel0`, `iChannel1`, `iChannel2`, `iChannel3`
- `vec3 uColor`
- `float time`, `iTime`, `iTimeDelta`
- `int iFrame`
- `vec3 uCamPos`, `uPlayerPos`, `iPlayerPos`
- `vec3 uCubePos`
- `vec2 uResolution`
- `vec3 iResolution`
- `vec3 iChannelResolution[4]`
- `float iChannelTime[4]`
- `mat4 model`, `view`, `projection`

Shadertoy notes:

- `.toy` files should contain the shader body plus `mainImage`.
- `fragCoord` is object-anchored surface space derived from `LocalPos` and the cube face normal, not screen space.
- `iResolution` and `uResolution` both describe that local surface canvas for `.toy` shaders.
- Real screen-space is still available through `gl_FragCoord.xy` or `uViewportSize`.
- World/object data is exposed as `WorldPos`, `LocalPos`, `iWorldPos`, `iObjectPos`, `iLocalPos`, `iSurfaceUV`, `iWorldNormal`, `iObjectNormal`, and `iLocalNormal`.
- The current player position is available as `uCamPos`, `uPlayerPos`, and `iPlayerPos`.
