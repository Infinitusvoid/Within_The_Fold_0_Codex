# Editable Shader Contract

Files in this folder are loaded directly at runtime and hot reloaded when they change.

- `default_vertex.glsl` is the shared vertex shader used by every editable fragment shader.
- `*.glsl` files here are treated as full OpenGL fragment shaders.
- `../shadertoy_shaders/*.toy` files are wrapped automatically so `mainImage(out vec4, in vec2)` works in-game.

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
- `gl_FragCoord.xy` is passed through as `fragCoord`.
- The current player position is available as `uCamPos`, `uPlayerPos`, and `iPlayerPos`.
