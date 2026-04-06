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
    return uv + vec2(
        sin(uv.x * 7.2 + iTime * 0.8),
        cos(uv.y * 4.5 - iTime * 1.2) * 0.2
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 13.1 + iTime * 1.5), cos(uv.y * 8.8 - iTime * 1.0));
}

vec3 palette(float t)
{
    float r = 0.1 + 0.6 * sin(t * 0.5 + iTime * 0.4);
    float g = 0.7 - 0.4 * cos(t * 1.1 - iTime * 0.3);
    float b = 0.3 + 0.5 * sin(t * 3.0 - iTime * 0.5);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 1.5) * 0.5 + 0.5;
    float c = cos(t * 1.0) * 0.3 + 0.7;
    float shift = sin(uv.x * 18.0 + t * 0.3) * 0.25;
    float ripple = sin(uv.y * 12.0 - t * 0.7) * 0.18;
    return uv * vec2(s, c) + vec2(shift, ripple);
}

vec3 colorFromUV(vec2 uv, float t) {
    float d = sin(uv.x * 6.5 + t * 0.5) * 0.5 + 0.5;
    float e = cos(uv.y * 5.5 - t * 0.6) * 0.5 + 0.5;
    float f = 0.5 + sin(uv.x * 3.5 + uv.y * 4.0 + t * 0.8) * 0.4;
    return vec3(d, e, f);
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
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
    vec2 uv = fragCoord/iResolution.xy;

    // --- Polar Coordinates ---
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float a = atan(p.y, p.x);

    // --- Flow Calculation ---
    vec2 flow_base = flowB(uv);
    vec2 flow_combined = flowA(flow_base);

    // --- Noise Field Generation ---
    vec2 flow_noise_uv = flow_combined * 6.0;
    float noise_val = noise(uv * 4.0 + iTime * 0.5);
    float flow_influence = noise(flow_noise_uv * 1.2 + iTime * 0.2);

    // --- Geometric Filtering ---
    float x_offset = 0.3 * sin(iTime * 1.6);
    float d1 = circle(uv, vec2(-x_offset * 0.8, 0.0), 0.2);
    float d2 = circle(uv, vec2( x_offset * 0.8, 0.0), 0.2);
    float d = smin(d1, d2, 0.15);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Depth and Wave Modulation ---
    float t_shift = iTime * 0.35 + iFrame * 0.02;

    // Depth calculation (Modulate based on polar angle and noise)
    float z = 1.0 / (r * 1.5 + 0.5 + 0.4 * sin(a * 25.0) + noise(uv * 8.0 + iTime * 0.5) * 0.6);

    // Wave calculation (Flow influenced wave mixing A and B patterns)
    vec2 wave_uv = flow_combined * 0.7;
    float wave = sin(r * 12.0 + dot(wave_uv, vec2(1.0, 0.0)) * 1.5) * cos(a * 9.0 + iTime * 4.0);

    // Phase modulation (Combination of flow and wave)
    float phase = flow_combined.x * 0.4 + wave * 1.5 * (1.0 - r * 0.6);

    // Density calculation (Controlled by depth and angular flow)
    float density = sin(a * 12.0 + iTime * 6.0) * exp(-r * r * 4.0) * (1.0 + flow_influence * 0.7);

    // Dynamic palette input
    float palette_t = 0.3 * iTime + sin(phase * 12.0) * 0.4 + z * 0.2;

    vec3 col = pal(palette_t);

    // --- Final Color Application ---

    // Apply geometric masking/ring effects
    col *= 0.4 + 0.6 * smoothstep(0.25, 0.0, abs(sin(25.0*r - 8.0*iTime)));

    // Apply flow influence and depth modulation
    col *= 1.1 + 1.8 * density; 
    col += sin(a * 40.0 + iTime * 20.0) * 0.4;
    col += pow(r, 1.8) * 0.6 * cos(a * 6.0 + iTime * 3.0);

    // Introduce final dynamic color shift
    col += noise(uv * 5.0 + iTime * 2.0) * 0.4;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
