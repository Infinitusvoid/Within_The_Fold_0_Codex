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
    return vec2(sin(uv.x * 7.0 + iTime * 2.0), cos(uv.y * 8.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.5 + iTime * 0.8) * 0.4,
        cos(uv.y * 10.0 + iTime * 1.2) * 0.3
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.1, 0.15, 0.3);
    c += 0.5 * sin(t * 0.3 + iTime * 0.7);
    c += 0.4 * cos(t * 1.2 + iTime * 0.5);
    return c;
}

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t*0.5));
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

    // Distance/Depth calculation
    float z = 1.0 / (r * 0.5 + 0.2);

    // Flow-based variations
    float f1 = sin(12.0*a + 5.0*z - 3.0*iTime);
    float f2 = cos(15.0*a - 3.5*z + 2.5*iTime);

    // Ring calculation (more intense)
    float ring = smoothstep(0.1, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation (mixing f1 and f2 heavily)
    float bands = smoothstep(0.2, 0.0, abs(f1 * f2 * 1.5));

    // Palette calculation
    float t = 0.1*iTime + 0.3*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.1 + 2.5*bands + 1.0*ring;
    col *= exp(-1.2*r * 0.8);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
