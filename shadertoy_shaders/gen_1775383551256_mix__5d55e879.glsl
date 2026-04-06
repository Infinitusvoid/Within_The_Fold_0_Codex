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

    // --- Polar Coordinates (Shader A style) ---
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // --- Flow Calculation (Combined A ? B style) ---
    vec2 flow_combined = flowB(uv);
    flow_combined = flowA(flow_combined);

    // --- Geometric Filtering (Shader A style) ---
    float x_offset = 0.25 * sin(iTime * 1.5);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.20);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.20);
    float d = smin(d1, d2, 0.15);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Depth and Wave Modulation (Shader B style) ---
    float t_shift = iTime * 0.3 + iFrame * 0.1;
    float z = floor((1.0/(r+0.2) + t_shift)*5.0)/5.0;

    float f1 = sin(12.0*a + 3.0*z - 1.5*iTime);
    float f2 = cos(8.0*r + 2.0*a + 1.0*iTime);

    float wave = sin(r * 4.0 + iTime * 1.5) * cos(a * 5.0);

    // Ring and Band calculations
    float ring = smoothstep(0.2, 0.0, abs(sin(15.0*r - 4.0*iTime)));
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Density calculation (Shader B style, applied radially)
    float density = sin(a * 15.0 + iTime * 5.0) * exp(-r * r * 2.5);

    // --- Phase Modulation (Combining flow and wave) ---
    float phase = flow_combined.x * 0.5 + wave * 0.5 * (1.0 - r * 0.4);

    // --- Fractal/Flow Position (Shader B style) ---
    // Calculate dynamic positional offsets based on flow
    vec2 flow_offset = flow_combined * 1.8;
    vec2 p_mod = flow_offset * (1.0 + r * 0.1);


    // --- Color calculation ---
    // Use the polar radius and flow for the palette input
    float t = 0.08*iTime + 0.05*z + 0.1*f1 + p_mod.y * 0.5;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff (Mixing A's structure with B's density)
    col *= 0.3 + 1.2*bands + 0.5*ring;
    col *= 1.2 + 4.0 * density;

    // Introduce final dynamic color shift (From A) and angular/radial emphasis (From B)
    col += vec3(sin(iTime*0.8 + a*2.0) * 0.2) * 0.6;
    col += sin(a * 20.0 + iTime * 10.0) * 0.5;
    col += cos(r * 6.0 + iTime * 5.0) * 0.4;

    // Apply depth/flow based darkening (From B)
    float depth_mod = 1.0 / (1.0 + 0.1*r*r * (1.0 + flow_offset.x*0.5));
    col *= depth_mod;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
