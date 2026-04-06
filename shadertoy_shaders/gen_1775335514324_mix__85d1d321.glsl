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

vec2 flow(vec2 uv)
{
    float a = iTime * 0.6;
    float b = iTime * 0.4;
    float flow_x = sin(uv.x * 6.0 + a * 2.0) * cos(uv.y * 4.0 - b * 1.5);
    float flow_y = cos(uv.y * 5.0 + a * 3.0) * sin(uv.x * 3.0 + b * 2.5);
    return uv + vec2(flow_x * 0.8, flow_y * 0.6);
}

vec3 wave_color(vec2 uv)
{
    float t = iTime * 3.0;
    float val = sin(uv.x * 15.0 + t) * cos(uv.y * 10.0 - t * 0.8);
    return vec3(val * 1.5, 1.0 - val * 0.5, val * 0.8);
}

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
    vec2 uv = fragCoord / iResolution.xy;

    // Apply coordinate centering and initial mapping (from B)
    vec2 uv_centered = uv * 2.0 - 1.0;

    // Apply flow warping (from A)
    vec2 f = flow(uv_centered * 8.0 + 0.5);

    // Apply wave distortion (from B)
    vec2 warped_uv = wave(f);
    warped_uv += uv_centered * 0.05; // Subtle movement

    // Calculate coordinate-based values (from B)
    float v = sin(warped_uv.x * 15.0 + iTime * 2.0);
    float u = cos(warped_uv.y * 15.0 + iTime * 1.8);
    float depth = pow(sin(warped_uv.x * 8.0 + warped_uv.y * 6.0 + iTime * 0.5), 3.0);

    // Base color calculation, incorporating A's wave color effect
    vec3 base_color = wave_color(warped_uv * 2.0);

    // Introduce flow-based noise modulation (from B)
    float noise_val = sin(f.x * 5.0 + f.y * 3.0);

    // Apply color shifts based on noise
    base_color.r = mix(base_color.r, 1.0, noise_val * 0.5);
    base_color.g = mix(base_color.g, 0.2, noise_val * 0.3);
    base_color.b = mix(base_color.b, 0.8, noise_val * 0.6);

    // Introduce radial glow effect based on depth (from B)
    float glow = smoothstep(0.5, 1.0, depth * 2.0);

    // Final color mixing
    vec3 final_col = base_color * glow;

    // Add secondary depth/flow interaction
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
