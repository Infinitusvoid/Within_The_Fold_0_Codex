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

vec2 flow1(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime), cos(uv.y * 7.0 + iTime * 1.5));
}

vec2 flow2(vec2 uv)
{
    return uv * 1.2 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8),
        cos(uv.y * 9.0 + iTime * 0.4)
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.1, 0.0, 0.4);
    c += 0.5 * sin(t * 1.5 + iTime * 0.6);
    c += 0.6 * sin(t * 2.0 + iTime * 0.3);
    c += 0.3 * cos(t * 3.0 + iTime * 0.1);
    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Primary flow
    uv = flow1(uv);

    // Radial distortion focusing on frequency interaction
    vec2 center = vec2(0.5);
    vec2 delta = uv - center;
    float distSq = dot(delta, delta);
    float scale = 1.0 + 3.0 * distSq; 
    uv = uv * scale;

    // Secondary flow
    uv = flow2(uv);

    // Palette calculation based on complex UV interaction
    float t = (uv.x * 6.0 + uv.y * 4.5) * 8.0 + iTime * 1.1;
    vec3 col = palette(t);

    // High frequency color modulation
    col += 1.5 * sin(uv.x * 10.0 + iTime * 0.7);
    col += 0.7 * cos(uv.y * 12.0 + iTime * 0.5);
    col += 0.4 * sin(uv.x + uv.y) * 0.5;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
