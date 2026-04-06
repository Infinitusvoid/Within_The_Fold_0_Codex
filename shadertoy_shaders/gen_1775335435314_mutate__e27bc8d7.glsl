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
    return vec2(sin(uv.x * 5.0 + iTime * 1.8), cos(uv.y * 4.5 + iTime * 2.5));
}

vec2 flowA(vec2 uv)
{
    return uv * 2.8 + vec2(
        sin(uv.x * 7.0 + iTime * 1.1),
        cos(uv.y * 6.0 + iTime * 1.9)
    );
}

vec3 palette(float t)
{
    vec3 c = vec3(0.5 + 0.5*sin(t * 1.5 + iTime * 0.2), 0.1 + 0.6*cos(t * 0.9 + iTime * 0.3), 0.5 + 0.4*sin(t * 1.1 + iTime * 0.1));
    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base Distortion (using flowB)
    uv = flowB(uv);

    // Rotation based on position and time, changing the pivot based on flow
    float angle = iTime * 4.0 + uv.x * 2.5 + uv.y * 1.0;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion (using flowA)
    uv = flowA(uv);

    // Calculate dynamic time based distortion parameter
    float t = (uv.x * 4.0 + uv.y * 3.0) * 5.0 + iTime * 1.0;
    vec3 col = palette(t);

    // Apply a strong wave distortion influence
    float wave = sin(uv.x * 15.0 + iTime * 1.5) * 0.5 + sin(uv.y * 10.0 + iTime * 1.0) * 0.5;

    // Complex color adjustments based on position and time, emphasizing contrast
    col += wave * 0.8;
    col += 0.5 * sin(iTime * 0.7 + uv.x * 15.0);
    col += 0.3 * cos(uv.y * 12.0 + iTime * 0.2);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
