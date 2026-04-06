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
    return vec2(sin(uv.x * 5.0 + iTime * 1.2), cos(uv.y * 5.0 + iTime * 1.5));
}

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.7) * 0.4,
        sin(uv.y * 4.5 + iTime * 1.1) * 0.35
    );
}

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Apply Flow from B
    uv = flowB(uv);
    uv = flowA(uv);

    // Radial/Angular Effects
    vec2 uv_final = uv;
    float r = length(uv_final);
    float a = atan(uv_final.y, uv_final.x);

    // Depth/Z calculation combining A's fractal style and B's distance influence
    float t_shift = iTime * 0.4 + iFrame * 0.05;
    float z = floor((1.0/(r*1.5+0.1) + t_shift)*5.0)/5.0;

    // Flow-based variations from B
    float f1 = sin(8.0*a + 2.5*z - 3.0*iTime);
    float f2 = cos(12.0*a - 2.0*z + 1.5*iTime);

    // Ring calculation from B
    float ring = smoothstep(0.2, 0.0, abs(sin(15.0*r - 4.0*iTime)));

    // Bands calculation from B
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Palette calculation using A's refined function structure
    float t = 0.08*iTime + 0.05*z + 0.1*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff (from B)
    col *= 0.1 + 1.5*bands + 0.7*ring;

    // Apply radial falloff (from A)
    col *= exp(-1.0*r * 0.7);

    // Introduce a final dynamic color shift (from A)
    col += vec3(sin(iTime*1.5) * 0.15) * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
