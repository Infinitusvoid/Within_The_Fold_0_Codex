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
    return vec2(sin(uv.x * 5.0 + iTime * 1.5), cos(uv.y * 5.0 + iTime * 2.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 6.0 + iTime * 0.5) * 0.3,
        cos(uv.y * 4.0 + iTime * 1.0) * 0.3
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

    // Palette calculation
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
