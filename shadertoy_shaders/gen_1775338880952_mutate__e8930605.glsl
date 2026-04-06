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
    return vec2(sin(uv.x * 10.0 + iTime * 1.5), cos(uv.y * 8.0 - iTime * 1.3));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 7.0 + iTime * 0.9) * 0.3,
        cos(uv.y * 5.5 - iTime * 0.75) * 0.35
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial wave structure based on waveB
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow based on complex angle (from Shader A)
    float angle = iTime * 0.3 + uv.x * 7.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure based on waveA
    warped_uv = waveA(warped_uv);

    // Apply spatial flow based on time and position (from Shader B)
    float flow_x = iTime * 0.6 + uv.x * 4.5;
    float flow_y = iTime * 0.4 + uv.y * 5.0;

    // Use flow for positional shifting
    warped_uv.x += sin(flow_x * 0.5) * 0.1;
    warped_uv.y += cos(flow_y * 0.7) * 0.15;

    // Generate dynamic value based on complex interaction
    float t = sin(warped_uv.x * 6.0 + iTime * 2.0) * 0.5 + cos(warped_uv.y * 5.0 + iTime * 1.0);

    vec3 col1 = palette(t * 1.2);

    // Introduce depth based on the phase shift
    float phase_shift = sin(warped_uv.x * 8.0 + iTime * 3.5) * 0.6;
    vec3 col2 = palette(phase_shift * 0.8 + warped_uv.y * 0.4);

    // Blend colors based on phase and flow interaction
    vec3 final_color = mix(col1, col2, phase_shift * 0.9 + flow_x * 0.2);

    // Fractal noise based on high frequency interaction
    float noise_factor = sin(warped_uv.x * 20.0 + iTime * 3.0) * cos(warped_uv.y * 12.0 - iTime * 0.9);

    // Introduce chromatic aberration effect based on flow
    float aberration = abs(uv.x - 0.5) * 3.0;
    final_color.r += aberration * 0.15;
    final_color.g -= aberration * 0.1;
    final_color.b += aberration * 0.05;

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.1, 0.2, 0.15), noise_factor * 0.7);

    // Final intensity adjustment
    final_color *= 1.7;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
