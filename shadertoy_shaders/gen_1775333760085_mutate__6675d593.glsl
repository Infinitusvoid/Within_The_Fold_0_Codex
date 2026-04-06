#version 330 core
uniform vec3 iResolution;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;
uniform vec4 iDate;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform float iChannelTime[4];
uniform vec3 iChannelResolution[4];
out vec4 FragColor;

vec2 wave(vec2 uv)
{
    float t = iTime * 0.8;
    float x = uv.x * 10.0 + t * 0.5;
    float y = uv.y * 10.0 + t * 0.4;
    float val = sin(x) + cos(y * 0.5);
    return uv * 1.5 + vec2(val * 0.1, val * 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Map coordinates to center and scale them
    uv = uv * 2.0 - 1.0;

    // Apply time-based translation and noise offset
    vec2 offset = uv * 20.0 + iTime * 1.5;

    // Introduce Perlin-like noise for complex distortion
    float noise_val = sin(offset.x * 5.0 + offset.y * 3.0);

    // Apply wave distortion
    uv = wave(uv);
    uv += offset * 0.05; // Add subtle movement based on offset

    // Calculate coordinate-based values
    float v = sin(uv.x * 15.0 + iTime * 2.0);
    float u = cos(uv.y * 15.0 + iTime * 1.8);
    float depth = pow(sin(uv.x * 8.0 + uv.y * 6.0 + iTime * 0.5), 3.0);

    // Base color calculation, emphasizing the depth effect
    vec3 base_color = vec3(v * 1.5, u * 1.2, 0.5);

    // Apply color shifts based on noise
    base_color.r = mix(base_color.r, 1.0, noise_val * 0.5);
    base_color.g = mix(base_color.g, 0.2, noise_val * 0.3);
    base_color.b = mix(base_color.b, 0.8, noise_val * 0.6);

    // Introduce a radial glow effect based on depth
    float glow = smoothstep(0.5, 1.0, depth * 2.0);

    // Final color mixing
    vec3 final_col = base_color * glow;

    // Add subtle time flow effect
    final_col.r += sin(iTime * 0.5) * 0.1;
    final_col.g += cos(iTime * 0.3) * 0.05;

    fragColor = vec4(final_col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
