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
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 5.5 - iTime * 0.8));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.7 + iTime * 0.4);
    float g = 0.3 + 0.6 * sin(t * 1.3 + iTime * 0.25);
    float b = 0.1 + 0.4 * cos(t * 2.0 - iTime * 0.15);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 5.0 + iTime * 0.9) * 0.25,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.22
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = waveB(uv);

    // Apply strong rotational flow
    float angle = iTime * 0.5 + uv.x * 6.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    uv *= rotationMatrix;

    uv = waveA(uv);

    // Generate flow factor based on complex spatial interaction
    float t = sin(uv.x * 5.0 + iTime * 1.5) * 3.0 + cos(uv.y * 5.0 + iTime * 0.7);
    vec3 col1 = palette(t);

    // Introduce a secondary color based on shifted phase interaction
    float phase = sin(uv.x * 9.0 + iTime * 2.5) * 0.8;
    vec3 col2 = palette(phase + uv.y * 0.7);

    // Blend colors using highly dynamic phase mixing
    vec3 final_color = mix(col1, col2, phase * 1.5);

    // Complex layered noise for deep shadow/highlight effects
    float noise_factor = sin(uv.x * 15.0 + iTime * 2.0) * cos(uv.y * 13.0 - iTime * 0.7);

    // Mix primary color with a vibrant cyan highlight based on noise
    vec3 highlight = vec3(0.0, 0.8, 1.0);
    final_color = mix(final_color, highlight, noise_factor * 1.8);

    // Apply an additional gradient effect based on the time
    float time_effect = sin(iTime * 2.0) * 0.1 + 0.5;
    final_color *= time_effect;

    // Final intensity boost and tone mapping
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
