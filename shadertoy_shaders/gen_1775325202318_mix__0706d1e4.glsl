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

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.3 + 0.7;
    float c = cos(t * 0.8) * 0.4 + 0.6;
    return uv * vec2(s, c) + vec2(sin(uv.x * 15.0 + t * 0.5), cos(uv.y * 20.0 - t * 0.6));
}

vec3 colorFromUV(vec2 uv, float t) {
    float value = sin(t * 2.0 + uv.x * 10.0) * 0.5 + 0.5;
    return vec3(value, 1.0 - value, 0.5);
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 0.5), cos(uv.y * 15.0 + iTime * 0.3));
}

vec3 palette(float t)
{
    return vec3(0.5 + 0.5*sin(t + iTime * 0.1), 0.5 + 0.5*sin(t + iTime * 0.2), 0.5 + 0.5*cos(t + iTime * 0.3));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 1.2 + iTime * 0.7) * 0.2,
        cos(uv.y * 1.5 + iTime * 0.6) * 0.3
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    uv = distort(uv, iTime);

    uv = waveB(uv);

    uv = waveA(uv);

    float t = (uv.x + uv.y) * 10.0 + iTime * 0.5;
    vec3 col = palette(t);

    col += 0.7 * sin(iTime * 0.3 + uv.xyx * 4.0 + vec3(0.2, 0.5, 0.8));
    col += 0.5 * sin(uv.y * 9.0 + (iTime + 0.15 * sin(uv.x * 42.42 + iTime)*sin(uv.x * 100.0 + iTime)));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
