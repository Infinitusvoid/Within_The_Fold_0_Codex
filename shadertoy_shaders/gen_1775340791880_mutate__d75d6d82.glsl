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
        sin(uv.x * 8.0 + iTime * 0.5) * 0.25,
        cos(uv.y * 12.0 + iTime * 0.7) * 0.15
    );
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.5*sin(t + iTime * 0.3), 0.6 + 0.3*cos(t + iTime * 0.1), 0.9 + 0.2*sin(t + iTime * 0.2));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base Flow (using flowB)
    uv = flowB(uv);

    // Rotation based on position and time, introducing more complex rotation
    float angle = iTime * 2.0 + uv.x * 1.0 + uv.y * 1.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion (using flowA)
    uv = flowA(uv);

    // Palette calculation based on warped coordinates
    float t = (uv.x * 4.0 + uv.y * 3.0) * 15.0 + iTime * 0.8;
    vec3 col = palette(t);

    // Complex color adjustments emphasizing intensity and swirl
    col += 0.6 * sin(iTime * 0.4 + uv.x * 6.0 + uv.y * 4.0);
    col += 0.4 * cos(uv.x * 15.0 + iTime * 0.2);
    col += 0.1 * sin(uv.y * 7.0 + iTime * 0.1);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
