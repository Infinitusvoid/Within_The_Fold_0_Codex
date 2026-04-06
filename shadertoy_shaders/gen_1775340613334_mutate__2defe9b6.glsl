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
    return uv + vec2(
        sin(uv.x * 6.0 + iTime * 1.2) * 0.15,
        cos(uv.y * 7.0 + iTime * 0.8) * 0.1
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 0.4) * 0.25,
        cos(uv.y * 5.0 + iTime * 0.6) * 0.2
    );
}

vec3 palette(float t)
{
    return vec3(
        0.05 + 0.3*sin(t * 0.8 + iTime * 0.1),
        0.3 + 0.4*cos(t * 1.1 + iTime * 0.2),
        0.6 + 0.2*sin(t * 0.9 + iTime * 0.3)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Flow Distortion
    uv = flowB(uv);

    // Phase shifting based on position and time
    float phase = uv.x * 4.0 + uv.y * 3.0 + iTime * 1.5;
    uv = uv + vec2(
        sin(phase * 0.5) * 0.2,
        cos(phase * 0.5) * 0.1
    );

    // Time-based rotation
    float angle = iTime * 1.2 + uv.x * 1.5 + uv.y * 1.2;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Final fine detail movement
    uv = flowA(uv);

    // Palette calculation
    float t = (uv.x * 5.0 + uv.y) * 12.0 + iTime * 0.7;
    vec3 col = palette(t);

    // Complex color adjustments emphasizing contrast
    col += 0.7 * sin(iTime * 0.8 + uv.x * 7.0);
    col += 0.4 * cos(uv.y * 9.0 + iTime * 0.5);
    col += 0.3 * sin(uv.x * 15.0 + uv.y * 5.0 + iTime * 0.3);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
