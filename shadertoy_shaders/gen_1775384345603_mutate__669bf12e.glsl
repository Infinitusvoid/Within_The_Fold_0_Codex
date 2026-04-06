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
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
}

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

vec2 flow(vec2 uv)
{
    float t = iTime * 1.5;
    float x = uv.x * 20.0 + t * 10.0;
    float y = uv.y * 15.0 + t * 7.5;

    float flow_x = sin(x * 0.4 + uv.y * 1.2) * cos(y * 0.3 + t * 0.6);
    float flow_y = cos(x * 0.5 + uv.x * 1.1) * sin(y * 0.5 + t * 0.5);

    return uv + vec2(flow_x * 1.8, flow_y * 1.8);
}

vec3 color_flow(vec2 uv)
{
    float t = iTime * 2.5;
    float angle = atan(uv.y, uv.x) * 6.28;

    float saturation = 0.5 + 0.5 * sin(angle * 3.0 + t * 1.5);
    float value = 0.4 + 0.6 * abs(sin(angle * 2.5 + t));

    float hue = angle + (uv.x * 0.8 + uv.y * 0.8) * 3.14159;

    return vec3(hue / 6.28, saturation, value);
}

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 2.0), cos(uv.y * 5.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 8.0 + iTime * 1.2) * 0.4,
        sin(uv.y * 4.0 + iTime * 0.8) * 0.3
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

vec3 pal(float t)
{
    return 0.5 + 0.5*sin(6.28318*(vec3(0.1, 0.3, 0.7) + t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Polar Coordinates ---
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // --- Flow Calculation ---
    vec2 flow_combined = flowB(uv);
    flow_combined = flowA(flow_combined);

    // --- Noise Field Generation ---
    // Use flow direction to sample noise
    vec2 flow_noise_uv = flow_combined * 10.0;
    float noise_val = noise(uv * 2.0 + iTime * 0.5);
    float flow_influence = noise(flow_noise_uv * 0.5 + iTime * 0.2);

    // --- Geometric Filtering ---
    float x_offset = 0.25 * sin(iTime * 1.5);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.20);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.20);
    float d = smin(d1, d2, 0.15);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Depth and Wave Modulation ---
    float t_shift = iTime * 0.3 + iFrame * 0.1;
    // Use radial distance and flow for depth calculation
    float z = floor((1.0/(r+0.2) + flow_combined.y * 0.5 + t_shift)*5.0)/5.0;

    float f1 = sin(12.0*a + 3.0*z - 1.5*iTime);
    float f2 = cos(8.0*r + 2.0*a + 1.0*iTime);

    float wave = sin(r * 4.0 + iTime * 1.5) * cos(a * 5.0);

    // Ring and Band calculations
    float ring = smoothstep(0.2, 0.0, abs(sin(15.0*r - 4.0*iTime)));
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Density calculation
    float density = sin(a * 15.0 + iTime * 5.0) * exp(-r * r * 2.5);

    // Phase modulation (Flow + Wave interaction)
    float phase = flow_combined.x * 0.3 + wave * 0.7 * (1.0 - r * 0.5);

    // Palette calculation
    float t = 0.08*iTime + 0.05*z + 0.1*f1;
    vec3 col = pal(t);

    // Apply flow influence to color mapping
    float flow_color_factor = 0.5 + flow_influence * 0.5;
    col *= flow_color_factor;

    // Combine modulation factors and apply falloff
    col *= 0.3 + 1.2*bands + 0.5*ring;
    col *= 1.5 + 3.0 * density; // Increased density influence

    // Introduce final dynamic color shift using noise
    col += noise(uv * 5.0 + iTime * 1.0) * 0.2;

    // Angular/Radial emphasis driven by phase and flow
    col += sin(a * 20.0 + iTime * 10.0) * 0.4;
    col += cos(r * 6.0 + iTime * 5.0) * 0.3;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
