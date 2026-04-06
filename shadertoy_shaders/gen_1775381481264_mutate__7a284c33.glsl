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
    return vec2(sin(uv.x * 7.0 + iTime * 1.8), cos(uv.y * 8.5 + iTime * 2.5));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.0 + iTime * 0.9) * 0.5,
        cos(uv.y * 10.0 + iTime * 1.3) * 0.5
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.1, 0.15, 0.3);
    c += 0.5 * sin(t * 0.5 + iTime * 0.8);
    c += 0.3 * sin(t * 3.0 + iTime * 1.1);
    return c;
}

vec3 pal(float t)
{
    return 0.1 + 0.9 * sin(3.14159*(vec3(0.1, 0.3, 0.7)+t*0.5));
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

    // Distance/Depth calculation
    float z = 1.0 / (r * 0.5 + 0.15);

    // Flow-based variations
    float f1 = sin(15.0*a + 8.0*z - 3.0*iTime);
    float f2 = cos(11.0*a - 4.0*z + 2.5*iTime);

    // Ring calculation (High contrast rings)
    float ring = smoothstep(0.005, 0.001, abs(sin(30.0*r - 7.0*iTime)));

    // Bands calculation (Extreme mixing)
    float bands = smoothstep(0.1, 0.0, abs(f1 * f2 * 2.5));

    // Palette calculation
    float t = 0.08*iTime + 0.5*z + 0.2*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.1 + 4.0*bands + 2.0*ring;
    col *= exp(-2.0*r * 1.2);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
