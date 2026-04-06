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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 12.0 + iTime * 0.4), cos(uv.y * 18.0 + iTime * 0.2));
}

vec3 palette(float t)
{
    return vec3(0.5 + 0.5*sin(t + iTime * 0.1), 0.5 + 0.5*cos(t + iTime * 0.2), 0.5 + 0.5*sin(t + iTime * 0.3));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 1.5 + iTime * 0.7) * 0.15,
        cos(uv.y * 2.0 + iTime * 0.6) * 0.25
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = waveB(uv);

    float angle = iTime * 0.6 + uv.x * 1.5 + uv.y * 0.3;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    uv = waveA(uv);

    float t = (uv.x * 2.0 + uv.y) * 15.0 + iTime * 0.3;
    vec3 col = palette(t);

    col += 0.6 * sin(iTime * 0.4 + uv.xyx * 3.0 + vec3(0.3, 0.6, 0.9));
    col += 0.4 * sin(uv.x * 8.0 + (iTime * 0.2 + 0.15 * sin(uv.y * 42.42 + iTime)*sin(uv.y * 100.0 + iTime)));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
