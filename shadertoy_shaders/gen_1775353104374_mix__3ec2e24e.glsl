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

vec2 flowB(vec2 uv)
{
    return vec2(sin(uv.x * 6.0 + iTime * 1.5), cos(uv.y * 6.0 + iTime * 1.8));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.6) * 0.3,
        cos(uv.y * 8.0 + iTime * 1.0) * 0.2
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.1, 0.2, 0.4);
    c += 0.5 * sin(t * 0.5 + iTime * 0.5);
    c += 0.4 * cos(t * 0.8 + iTime * 0.3);
    return c;
}

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply Flow
    uv = flowB(uv);
    uv = flowA(uv);

    // Radial/Angular Effects
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    float z = 1.0 / (r + 0.18);

    // Flow-based variations
    float f1 = sin(10.0*a + 3.0*z - 2.0*iTime);
    float f2 = sin(16.0*a - 4.0*z + 1.7*iTime);

    // Ring calculation
    float ring = smoothstep(0.2, 0.0, abs(sin(10.0*r - 3.0*iTime)));

    // Bands calculation
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Palette calculation
    float t = 0.08*iTime + 0.08*z + 0.15*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.2 + 1.6*bands + 0.6*ring;
    col *= exp(-0.9*r);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
