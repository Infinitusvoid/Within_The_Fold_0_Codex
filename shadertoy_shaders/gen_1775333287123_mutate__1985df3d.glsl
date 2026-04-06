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
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 1.5));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.7 + iTime * 0.4);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.5 * cos(t * 2.1 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 1.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.1,
        cos(uv.y * 4.5 - iTime * 1.1) * 0.15
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = waveB(uv);

    // Introduce complex rotational flow
    float angle = iTime * 0.4 + uv.x * 10.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    uv *= rotationMatrix;

    uv = waveA(uv);

    // Generate base flow factor based on combined spatial interaction
    float flow_t = sin(uv.x * 5.0 + iTime * 1.5) * 1.5 + cos(uv.y * 6.0 + iTime * 0.8);
    vec3 col1 = palette(flow_t);

    // Introduce secondary wave interaction based on high frequency phase
    float phase_shift = sin(uv.x * 15.0 + iTime * 2.5) * 0.6;
    vec3 col2 = palette(phase_shift + uv.y * 1.2);

    // Blend the colors using flow interaction
    vec3 final_color = mix(col1, col2, phase_shift * 0.8);

    // Complex fractal noise using multi-layered interaction
    float noise_factor = sin(uv.x * 20.0 + iTime * 3.0) * cos(uv.y * 22.0 - iTime * 1.3);

    // Introduce extreme contrast based on flow
    final_color = mix(final_color, vec3(0.9, 0.1, 0.1), noise_factor * 0.3);

    // Final intensity boost and complex color shift
    final_color *= 1.3;
    final_color.r = pow(final_color.r, 1.2);
    final_color.g = pow(final_color.g, 1.2);
    final_color.b = pow(final_color.b, 1.2);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
