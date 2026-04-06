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

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base Flow
    uv = flowB(uv);

    // Radial Distortion based on distance from center
    vec2 center = vec2(0.5);
    vec2 delta = uv - center;
    float dist = dot(delta, delta);
    float scale = 1.0 + 2.0 * dist; // Increase distortion towards edges
    uv = uv * scale;

    // Secondary Flow
    uv = flowA(uv);

    // Palette calculation
    float t = (uv.x * 5.0 + uv.y * 4.0) * 10.0 + iTime * 1.2;
    vec3 col = palette(t);

    // Complex color adjustments emphasizing high frequency interaction
    col += 1.0 * sin(uv.x * 8.0 + iTime * 0.5);
    col += 0.8 * cos(uv.y * 10.0 + iTime * 0.9);
    col += 0.5 * sin(uv.x * 3.0 + uv.y * 3.0 + iTime * 0.7);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
