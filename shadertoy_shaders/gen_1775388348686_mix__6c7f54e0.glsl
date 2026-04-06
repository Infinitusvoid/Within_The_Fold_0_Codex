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

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }
vec3 pal(float t)
{
    vec3 c = vec3(0.1, 0.15, 0.3);
    c += 0.5 * sin(t * 0.3 + iTime * 0.7);
    c += 0.4 * cos(t * 1.2 + iTime * 0.5);
    return c;
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
vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 1.5), cos(uv.y * 5.0 + iTime * 2.0));
}
vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 6.0 + iTime * 0.5) * 0.3,
        cos(uv.y * 4.0 + iTime * 1.0) * 0.3
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Flow and Warping (Shader B) ---
    uv = flowB(uv);
    uv = flowA(uv);

    // --- Geometric Filtering (Shader A) ---
    // Calculate spatial mask based on distance
    float x_offset = 0.3 * sin(iTime * 1.8);
    float d1 = circle(uv, vec2(-x_offset, 0.0), 0.18);
    float d2 = circle(uv, vec2( x_offset, 0.0), 0.18);
    float d = smin(d1, d2, 0.12);
    float shape_mask = smoothstep(0.01, 0.0, d);

    // --- Radial/Angular Effects (Shader B) ---
    vec2 p = 2.0 * iResolution.xy;
    vec2 center = vec2(0.5);
    vec2 coord = uv - center;

    float r = length(coord);
    float a = atan(coord.y, coord.x);

    // Distance/Depth calculation (Modified perspective)
    float z = 1.0 / (r * 0.3 + 0.1);

    // Flow-based variations
    float f1 = sin(10.0*a + 8.0*z - 4.0*iTime);
    float f2 = cos(12.0*a - 4.5*z + 3.0*iTime);

    // Ring calculation (focused on radius)
    float ring = smoothstep(0.1, 0.01, abs(sin(20.0*r - 6.0*iTime)));

    // Bands calculation (mixing f1 and f2)
    float bands = smoothstep(0.3, 0.0, abs(f1 * f2 * 1.8));

    // --- Palette Calculation (Shader B) ---
    // Time and depth driven palette calculation
    float t = 0.1*iTime + 0.2*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.05 + 3.0*bands + 2.0*ring;
    col *= exp(-1.5*r * 1.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
