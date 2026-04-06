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
    return vec2(sin(uv.x * 12.0 + iTime * 2.0), cos(uv.y * 9.0 - iTime * 1.4));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 1.2 + iTime * 0.7);
    float g = 0.1 + 0.8 * sin(t * 0.9 + iTime * 0.5);
    float b = 0.4 + 0.4 * cos(t * 1.5 - iTime * 0.3);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 4.0 + vec2(
        sin(uv.x * 6.0 + iTime * 1.5) * 0.2,
        cos(uv.y * 7.0 - iTime * 1.2) * 0.15
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base wave structure
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow based on complex angle
    float angle = iTime * 0.4 + uv.x * 6.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure
    warped_uv = waveA(warped_uv);

    // Apply spatial flow (more complex interaction)
    float flow_x = iTime * 1.0 + uv.x * 3.0;
    float flow_y = iTime * 0.8 + uv.y * 4.5;

    // Use flow for positional shifting
    warped_uv.x += sin(flow_x * 2.0) * 0.15;
    warped_uv.y += cos(flow_y * 1.5) * 0.1;

    // Generate dynamic value based on complex interaction
    float t = sin(warped_uv.x * 10.0 + iTime * 2.5) * cos(warped_uv.y * 8.0 + iTime * 1.0);

    vec3 col1 = palette(t * 1.5);

    // Introduce a secondary color modulation based on high frequency interaction
    float phase_shift = sin(warped_uv.x * 15.0 + iTime * 4.0) * 0.4;
    vec3 col2 = palette(phase_shift * 1.3 + warped_uv.y * 0.6);

    // Blend colors based on flow interaction
    vec3 final_color = mix(col1, col2, phase_shift * 0.5 + flow_x * 0.2);

    // Fractal noise based on high frequency interaction
    float noise_factor = sin(warped_uv.x * 30.0 + iTime * 5.0) * cos(warped_uv.y * 16.0 - iTime * 2.0);

    // Introduce chromatic aberration based on UV position and flow
    float aberration = abs(uv.x - 0.5) * 4.0;
    final_color.r += aberration * 0.2;
    final_color.b -= aberration * 0.2;

    // Final color mixing and contrast boost
    vec3 base_noise = vec3(0.05, 0.25, 0.03);
    final_color = mix(final_color, base_noise, noise_factor * 0.9);

    // Intensity adjustment based on time variation
    float intensity = 1.0 + 0.3 * sin(iTime * 0.7);
    final_color *= intensity;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
