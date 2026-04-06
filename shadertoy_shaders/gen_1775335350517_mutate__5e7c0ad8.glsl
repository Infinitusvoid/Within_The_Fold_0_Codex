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

vec2 flowA(vec2 uv)
{
    // Introduce complex flow based on time and position
    float angle = iTime * 0.5 + uv.x * 5.0 + uv.y * 3.0;
    float flowX = sin(angle * 3.0) * 0.5;
    float flowY = cos(angle * 2.0) * 0.5;
    return uv + vec2(flowX, flowY);
}

vec2 waveB(vec2 uv)
{
    // Base movement (more oscillatory)
    return vec2(sin(uv.x * 8.0 + iTime * 1.0), cos(uv.y * 12.0 + iTime * 0.8));
}

vec3 palette(float t)
{
    // Dynamic palette based on complex interaction
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.3);
    float g = 0.2 + 0.6 * cos(t * 1.2 + iTime * 0.2);
    float b = 0.9 - 0.3 * sin(t * 1.5 + iTime * 0.1);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base movement (using waveB)
    uv = waveB(uv);

    // Rotation based on position and time
    float angle = iTime * 2.0 + uv.x * 1.5 + uv.y * 1.0;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary Distortion (using flowA)
    uv = flowA(uv);

    // Palette calculation
    float t = (uv.x * 4.0 + uv.y) * 5.0 + iTime * 0.4;
    vec3 col = palette(t);

    // Complex color adjustments based on interaction
    float noise = sin(uv.x * 6.0 + iTime * 1.5) * cos(uv.y * 5.0 + iTime * 0.5);

    col += 0.6 * noise;
    col += 0.4 * sin(iTime * 2.5 + uv.x * 10.0);
    col += 0.3 * cos(uv.y * 15.0 + iTime * 0.6);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
