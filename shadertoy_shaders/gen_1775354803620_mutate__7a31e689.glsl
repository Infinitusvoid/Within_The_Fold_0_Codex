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
    return vec2(sin(uv.x * 5.0 + iTime * 2.0), cos(uv.y * 5.0 + iTime * 3.0));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 8.0 + iTime * 1.2) * 0.4,
        sin(uv.y * 4.0 + iTime * 0.8) * 0.3
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
    float t_shift = iTime * 0.3 + iFrame * 0.1;
    float z = floor((1.0/(r+0.2) + t_shift)*5.0)/5.0;

    // Flow-based variations
    float f1 = sin(12.0*a + 3.0*z - 1.5*iTime);
    float f2 = cos(8.0*r + 2.0*a + 1.0*iTime);

    // Ring calculation
    float ring = smoothstep(0.2, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Palette calculation
    float t = 0.08*iTime + 0.05*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff
    col *= 0.3 + 1.2*bands + 0.5*ring;

    // Apply radial falloff
    col *= exp(-1.0*r * 1.5);

    // Introduce final dynamic color shift
    col += vec3(sin(iTime*0.8 + a*2.0) * 0.2) * 0.6;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
