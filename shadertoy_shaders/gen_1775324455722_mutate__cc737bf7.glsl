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
    return vec2(sin(uv.x * 8.0 + iTime * 0.5), cos(uv.y * 12.0 - iTime * 0.3));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.7 + iTime * 0.3);
    float g = 0.4 + 0.4 * cos(t * 1.1 - iTime * 0.2);
    float b = 0.2 + 0.6 * sin(t * 1.5 + iTime * 0.1);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.6) * 0.08,
        cos(uv.y * 2.5 - iTime * 0.4) * 0.12
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = waveB(uv);

    float angle = iTime * 0.5 + uv.x * 3.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    uv *= rotationMatrix;

    uv = waveA(uv);

    // Generate a complex flow factor based on spatial frequency and time
    float t = (uv.x * 5.0 + uv.y * 4.0) * 2.0 + iTime * 0.5;
    vec3 col = palette(t);

    // Modulate color based on dynamic spatial shifts
    float strength = 1.0 - abs(sin(uv.x * 6.0 + iTime * 0.2)) * 0.5;
    col *= strength * 1.5;

    // Introduce subtle fractal noise via combined frequency interaction
    float noise_factor = sin(uv.x * 10.0 + iTime * 0.4) * cos(uv.y * 9.0 - iTime * 0.5);

    // Apply noise to shift the color based on the noise intensity
    col = mix(col, vec3(0.0, 0.5, 1.0), noise_factor * 0.4);

    // Final intensity boost
    col = pow(col, vec3(1.2));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
