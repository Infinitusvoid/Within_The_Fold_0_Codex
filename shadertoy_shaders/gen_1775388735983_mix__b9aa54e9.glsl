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

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.6 + iTime * 0.3);
    float g = 0.4 + 0.6 * sin(t * 1.1 + iTime * 0.2);
    float b = 0.2 + 0.4 * cos(t * 1.5 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.4 + 0.6;
    float c = cos(t * 0.8) * 0.3 + 0.5;
    float shift = sin(uv.x * 14.0 + t * 0.2) * 0.15;
    float ripple = cos(uv.y * 16.0 - t * 0.4) * 0.1;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 5.0 + t * 0.3) * 0.5 + 0.5;
    float e = cos(uv.y * 6.0 - t * 0.4) * 0.5 + 0.5;
    float f = 0.2 + sin(uv.x * 3.0 + uv.y * 2.0 + t * 0.5) * 0.3;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float circle(vec2 p, vec2 c, float r)
{
    return length(p - c) - r;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize and base inversion setup
    uv = uv * 2.0 - 1.0;

    // Apply initial timing modulation and structure smoothing
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // 1. Complex Motion Baseline (Rotation and Distortion)
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv = rotationMatrix * uv;

    float angle2 = iTime * 0.8 + uv.x * 0.5 + uv.y * 0.3;
    uv = rotate(uv, angle2);

    vec2 distorted_uv = distort(uv, iTime);

    // 2. Chain Wave Patterns (Mixing A and B)
    distorted_uv = waveA(distorted_uv);
    distorted_uv = waveB(distorted_uv);

    // 3. Polar Coordinates and Radial Flow (Mixing B)
    vec2 center = vec2(0.5);
    vec2 p = distorted_uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Introduce grid pattern based on position and time
    float x = a / 3.14159;
    float y = 0.2 / max(r, 0.001) + iTime * 1.5;
    float grid = 0.5 + 0.5 * sin(20.0 * y + 10.0 * x);

    // Combine flow distortion and grid structure
    float flow_offset = sin(distorted_uv.x * 18.0 + iTime * 2.5) * 0.25;
    float final_flow_val = flow_offset * 0.5 + grid * 0.5;


    // 4. Material Data Retrieval (from A)
    vec3 col_base = colorFromUV(distorted_uv, iTime);

    // Dynamic Variable Generation based on radial position
    float t = r * 1.5 + iTime * 1.2;
    vec3 col_palette = palette(t * 1.5);

    // Mix base color and palette using flow/grid as modulation
    vec3 mixed_color = mix(col_base, col_palette, final_flow_val);

    // Introduce chromatic aberration based on angular position (from B)
    float ca_factor = 1.0 - r * 0.3;
    mixed_color += vec3(sin(a * 10.0) * ca_factor, cos(a * 10.0) * ca_factor, 0.0) * 0.2;

    // 5. Radial Depth and Smoothstep Masking (from B)
    float depth_haze = 1.0 - smoothstep(0.0, 0.15, r);
    mixed_color *= depth_haze;

    // Apply geometric shape mask
    float x_offset = 0.3 * sin(iTime * 1.8);
    float d1 = circle(distorted_uv, vec2(-x_offset, 0.0), 0.18);
    float d2 = circle(distorted_uv, vec2( x_offset, 0.0), 0.18);
    float d = smin(d1, d2, 0.12);
    float shape_mask = smoothstep(0.01, 0.0, d);
    mixed_color *= (1.0 - shape_mask) * 0.5 + shape_mask * 1.5;

    // 6. Fractal Noise based on high frequency interaction (from A)
    float noise_factor = sin(distorted_uv.x * 15.0 + iTime * 3.0) * cos(distorted_uv.y * 10.0 - iTime * 1.5);

    // Apply noise and contrast boost
    mixed_color = mix(mixed_color, vec3(0.0, 0.2, 0.1), noise_factor * 0.8);

    // Final intensity adjustment
    mixed_color *= 1.2;

    fragColor = vec4(mixed_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
