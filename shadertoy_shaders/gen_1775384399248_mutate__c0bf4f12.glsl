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

vec2 flowB(vec2 uv)
{
    // Swirling flow
    float angle = uv.x * 3.0 + iTime * 1.5;
    float radius = length(uv);
    return vec2(cos(angle * 2.0 + radius * 4.0), sin(angle * 2.0 + radius * 4.0));
}

vec2 flowA(vec2 uv)
{
    // Base flow with time offset
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 1.0) * 0.5,
        cos(uv.y * 5.0 + iTime * 1.2) * 0.5
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply Flow
    uv = flowB(uv);
    uv = flowA(uv);

    // Apply Rotation (from Shader A)
    vec2 p = uv * rot(0.5*iTime);

    // Radial/Angular Effects (from Shader B)
    float r = length(p);
    float a = atan(p.y, p.x);

    // Distance/Depth calculation (from Shader B)
    float z = 1.0 / (r * 0.5 + 0.2);

    // Flow-based variations (from Shader B)
    float f1 = sin(12.0*a + 5.0*z - 3.0*iTime);
    float f2 = cos(15.0*a - 3.5*z + 2.5*iTime);

    // Ring calculation (from Shader B)
    float ring = smoothstep(0.1, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation (from Shader B)
    float bands = smoothstep(0.2, 0.0, abs(f1 * f2 * 1.5));

    // Palette calculation (using Shader B's palette)
    float t = 0.1*iTime + 0.3*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff (mixing Shader A's glow concept)
    float glow = 1.0 - smoothstep(0.0, 0.2, r);

    // Apply modulation from B (bands and ring)
    col *= 0.1 + 2.5*bands + 1.0*ring;

    // Apply exponential falloff (from Shader A)
    col *= exp(-1.2*r * 0.8);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
