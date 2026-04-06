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
    return vec2(sin(uv.x * 6.0 + iTime * 1.5), cos(uv.y * 9.0 + iTime * 2.2));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.7) * 0.6,
        cos(uv.y * 12.0 + iTime * 1.0) * 0.4
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.1, 0.2, 0.5);
    c += 0.5 * sin(t * 0.4 + iTime * 0.6);
    c += 0.4 * sin(t * 2.0 + iTime * 0.9);
    return c;
}

vec3 pal(float t)
{
    return 0.3 + 0.7 * sin(6.28318*(vec3(0.1, 0.5, 0.8)+t*0.5));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply Flow
    uv = flowB(uv);
    uv = flowA(uv);

    // Radial/Angular Effects
    vec2 center = vec2(0.5);
    vec2 disp = uv - center;
    float r = length(disp);
    float a = atan(disp.y, disp.x);

    // Distance/Depth calculation (More complex interaction)
    float z = 1.0 / (r * 0.8 + 0.5);

    // Flow-based variations
    float f1 = sin(10.0*a + 5.0*z - 4.0*iTime);
    float f2 = cos(12.0*a - 3.0*z + 2.0*iTime);

    // Ring calculation (High contrast rings)
    float ring = smoothstep(0.01, 0.005, abs(sin(20.0*r - 5.0*iTime)));

    // Bands calculation (Extreme mixing)
    float bands = smoothstep(0.1, 0.0, abs(f1 * f2 * 1.8));

    // Palette calculation
    float t = 0.05*iTime + 0.2*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.15 + 3.0*bands + 1.5*ring;
    col *= exp(-1.5*r * 1.0);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
