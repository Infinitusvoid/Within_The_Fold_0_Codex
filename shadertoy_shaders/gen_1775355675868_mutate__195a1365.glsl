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
    return vec2(sin(uv.x * 6.0 + iTime * 3.0), cos(uv.y * 7.0 + iTime * 4.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 10.0 + iTime * 1.5) * 0.5,
        sin(uv.y * 5.0 + iTime * 2.5) * 0.4
    );
}

vec3 pal(float t)
{
    return 0.5 + 0.5*sin(6.28318*(vec3(0.1, 0.3, 0.7) + t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply Flow from B and A
    uv = flowB(uv);
    uv = flowA(uv);

    // Radial/Angular Effects
    vec2 uv_final = uv;
    float r = length(uv_final);
    float a = atan(uv_final.y, uv_final.x);

    // Depth/Z calculation
    float t_shift = iTime * 0.4 + iFrame * 0.1;
    float z = floor((1.0/(r+0.1) + t_shift)*4.0)/4.0;

    // Flow-based variations
    float f1 = sin(15.0*a + 5.0*z - 2.0*iTime);
    float f2 = cos(10.0*r + 3.0*a + 1.5*iTime);

    // Ring calculation (modified threshold)
    float ring = smoothstep(0.3, 0.1, abs(sin(20.0*r - 5.0*iTime)));

    // Bands calculation (modified interaction)
    float bands = smoothstep(0.2, 0.0, abs(f1 * f2 * 0.7));

    // Palette calculation
    float t = 0.06*iTime + 0.04*z + 0.15*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.4 + 1.5*bands + 0.6*ring;

    // Apply radial falloff (stronger falloff)
    col *= exp(-2.0*r * 1.2);

    // Introduce final dynamic color shift (more complex shift)
    col += vec3(sin(iTime*1.1 + a*3.0) * 0.25) * 0.7;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
