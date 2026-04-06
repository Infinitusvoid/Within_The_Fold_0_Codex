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
    float t_shift = iTime * 0.5 + iFrame * 0.1;
    float z = floor((1.0/(r+0.15) + t_shift)*6.0)/6.0;

    // Flow-based variations from B
    float f1 = sin(10.0*a + 3.0*z - 2.0*iTime);
    float f2 = sin(16.0*a - 4.0*z + 1.7*iTime);

    // Ring calculation from B
    float ring = smoothstep(0.2, 0.0, abs(sin(10.0*r - 3.0*iTime)));

    // Bands calculation from B
    float bands = smoothstep(0.25, 0.0, abs(f1 * f2));

    // Palette calculation using A's refined function structure
    float t = 0.08*iTime + 0.08*z + 0.15*f1;
    vec3 col = pal(t);

    // Combine modulation factors and apply falloff (from B)
    col *= 0.2 + 1.6*bands + 0.6*ring;

    // Apply radial falloff (from A)
    col *= exp(-0.8*r);

    // Introduce a final dynamic color shift (from A)
    col += vec3(sin(iTime*0.5) * 0.1) * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
