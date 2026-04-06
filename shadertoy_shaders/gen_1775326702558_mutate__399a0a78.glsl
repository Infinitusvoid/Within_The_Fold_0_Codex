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
    return vec2(sin(uv.x * 6.0 + iTime * 0.5), cos(uv.y * 7.0 - iTime * 0.4));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.6 + iTime * 0.3);
    float g = 0.4 + 0.6 * sin(t * 1.1 + iTime * 0.2);
    float b = 0.2 + 0.4 * cos(t * 1.5 - iTime * 0.1);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.7) * 0.15,
        cos(uv.y * 3.5 - iTime * 0.5) * 0.18
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = waveB(uv);

    // Apply rotational flow
    float angle = iTime * 0.3 + uv.x * 5.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    uv *= rotationMatrix;

    uv = waveA(uv);

    // Generate flow factor based on combined spatial interaction
    float t = sin(uv.x * 3.0 + iTime * 1.0) * 2.0 + cos(uv.y * 4.0 + iTime * 0.5);
    vec3 col1 = palette(t);

    // Introduce a secondary color based on phase shifts
    float phase = sin(uv.x * 7.0 + iTime * 2.0) * 0.5;
    vec3 col2 = palette(phase + uv.y * 0.5);

    // Blend the colors using frequency interaction
    vec3 final_color = mix(col1, col2, phase * 0.5);

    // Complex fractal noise using high frequency interaction
    float noise_factor = sin(uv.x * 12.0 + iTime * 1.5) * cos(uv.y * 11.0 - iTime * 0.6);

    // Apply noise to introduce deep shadows/highlights
    final_color = mix(final_color, vec3(0.1, 0.9, 0.5), noise_factor * 0.5);

    // Final intensity boost and slight color shift
    final_color *= 1.2;
    final_color.r = pow(final_color.r, 1.1);
    final_color.g = pow(final_color.g, 1.1);
    final_color.b = pow(final_color.b, 1.1);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
