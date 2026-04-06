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
    return vec2(sin(uv.x * 8.0 + iTime * 2.0), cos(uv.y * 10.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 6.5 + iTime * 1.2) * 0.7,
        cos(uv.y * 11.5 + iTime * 1.5) * 0.3
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.0, 0.2, 0.8);
    c += 0.5 * sin(t * 0.5 + iTime * 0.8);
    c += 0.3 * cos(t * 3.0 + iTime * 1.1);
    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply combined Flow
    uv = flowB(uv);
    uv = flowA(uv);

    // Radial/Angular Effects
    vec2 center = vec2(0.5);
    vec2 disp = uv - center;
    float r = length(disp);
    float a = atan(disp.y, disp.x);

    // Distance/Depth calculation (modified perspective)
    float z = 1.0 / (r * 1.2 + 0.4);

    // Flow-based variations
    float f1 = sin(15.0*a + 7.0*z - 5.0*iTime);
    float f2 = cos(10.0*a - 4.0*z + 3.0*iTime);

    // Ring calculation (modified scale)
    float ring = smoothstep(0.01, 0.002, abs(sin(40.0*r - 8.0*iTime)));

    // Bands calculation (more intense)
    float bands = smoothstep(0.15, 0.0, abs(f1 * f2 * 2.0));

    // Palette calculation
    float t = 0.1*iTime + 0.3*z + 0.05*f1;
    vec3 col = palette(t);

    // Combine modulation factors (Emphasis on bands)
    float modulation = (1.0 - bands) * 0.6 + ring * 1.8;

    // Apply color shift based on flow difference
    col += (f1 - f2) * 0.2;

    // Apply radial falloff (steeper falloff)
    col *= exp(-2.0*r * 1.5);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
