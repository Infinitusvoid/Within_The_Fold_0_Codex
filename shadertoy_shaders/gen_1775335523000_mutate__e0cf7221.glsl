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
    return vec2(sin(uv.x * 5.0 + iTime * 0.3), cos(uv.y * 7.0 + iTime * 0.5));
}

vec2 flowA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 10.0 + iTime * 0.4) * 0.3,
        cos(uv.y * 8.0 + iTime * 0.6) * 0.2
    );
}

vec3 palette(float t)
{
    return mix(vec3(0.1, 0.2, 0.5), vec3(1.0, 0.8, 0.1), smoothstep(0.0, 0.5, t));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Primary flow calculation
    vec2 flow = flowB(uv);

    // Displacement based on flow
    uv = uv + flow * 1.2;

    // Complex flow interaction
    float t = iTime * 0.7;
    uv.x += sin(uv.y * 5.0 + t) * 0.4;
    uv.y += cos(uv.x * 6.0 + t * 1.5) * 0.3;

    // Rotation based on position and time
    float angle = iTime * 3.0 + uv.x * 4.0 + uv.y * 2.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = uv * rotationMatrix;

    // Color mapping based on distorted position
    float distortionValue = (uv.x + uv.y) * 1.5;
    vec3 col = palette(distortionValue * 0.5 + 0.2);

    // Final modulation using time and position
    col += sin(uv.x * 8.0 + iTime * 1.1) * 0.4;
    col += cos(uv.y * 12.0 + iTime * 0.9) * 0.2;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
