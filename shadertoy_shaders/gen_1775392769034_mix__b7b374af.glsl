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

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

vec3 palette(float t)
{
    vec3 c = vec3(0.05, 0.2, 0.5);
    c += 0.5 * sin(t * 0.3 + iTime * 0.7);
    c += 0.4 * cos(t * 1.2 + iTime * 0.5);
    return c;
}

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 2.0), cos(uv.y * 4.0 + iTime * 1.5));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 3.0 + iTime * 1.2) * 0.2
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // --- Flow and Warping (Mixing A and B flow) ---
    uv = flowB(uv);
    uv = flowA(uv);

    // --- Polar Coordinates and Depth (from B, adapted for A's geometry) ---
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // Distance/Depth calculation (from A's perspective modeling)
    float z = 1.0 / (r * 0.5 + 0.1);

    // Time modulation based on position and rotation (from B)
    float t = iTime * 1.5 + r * 3.0 + theta * 4.0;

    // Introduce high frequency oscillation using the polar components (from B)
    float r_mod = sin(t * 8.0 + theta * 20.0) * 0.5 + 0.5;
    float g_mod = cos(t * 5.0 + r * 10.0) * 0.5 + 0.5;
    float b_mod = sin(t * 11.0 + theta * 22.0) * 0.5 + 0.5;

    // Introduce fractal noise based on distance and time (from B)
    float noise = fract(sin(t * 50.0 + r * 100.0) * 43758.5453);

    // --- Color Generation (Mixing A's palette and B's modulation) ---

    // Base palette input, using distance heavily (from B)
    float p_input = 0.1*iTime + 0.2*z + 0.1*sin(r*2.0); // Combined time/depth complexity

    vec3 base_color = palette(p_input);

    // Mix colors using the modulation function and noise (from B)
    vec3 color = palette(p_input) * r_mod;
    color += palette(p_input + 0.1) * g_mod;
    color += palette(p_input + 0.2) * b_mod;

    // Apply fractal noise shift and phase shift (from B)
    color += noise * 0.15;
    color += sin(t * 1.5) * 0.1;

    // --- Geometric Masking (from A) ---

    float x_offset = 0.3 * sin(iTime * 1.8);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.18);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.18);
    float d = smin(d1, d2, 0.12);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // Apply geometric mask from A to the final color
    color *= (1.0 - shape_mask) * 0.6 + shape_mask * 1.4;

    // Apply radial falloff and final ambient lighting (from A/B combination)
    color *= exp(-1.5*r * 1.5);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
