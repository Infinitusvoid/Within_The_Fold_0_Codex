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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.28,0.6)+t)); }

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
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
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Base Wave structure (from B)
    vec2 warped_uv = waveB(uv);

    // 2. Apply rotational flow based on complex angle (from A)
    float angle = iTime * 0.2 + uv.x * 6.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // 3. Apply secondary wave structure (from B)
    warped_uv = waveA(warped_uv);

    // 4. Apply complex spatial flow based on A
    float flow_x = iTime * 0.5 + uv.x * 3.0;
    float flow_y = iTime * 0.3 + uv.y * 4.0;

    // Use flow for positional shifting (from B)
    warped_uv.x += sin(flow_x * 0.8) * 0.15;
    warped_uv.y += cos(flow_y * 0.6) * 0.15;

    // 5. Generate dynamic value based on complex interaction (from B)
    float t = sin(warped_uv.x * 5.0 + iTime * 1.5) + cos(warped_uv.y * 4.5 + iTime * 0.5);

    // Use the combined palette function (from A)
    vec3 col1 = pal(t * 1.5);

    // Introduce depth based on the phase shift (from B)
    float phase_shift = sin(warped_uv.x * 6.0 + iTime * 3.0) * 0.5;
    vec3 col2 = pal(phase_shift + warped_uv.y * 0.3);

    // Blend colors based on phase and flow interaction (from B)
    vec3 final_color = mix(col1, col2, phase_shift * 0.7 + flow_x * 0.15);

    // Fractal noise based on high frequency interaction (from A/B interaction)
    float noise_factor = sin(warped_uv.x * 15.0 + iTime * 2.0) * cos(warped_uv.y * 10.0 - iTime * 0.8);

    // Introduce chromatic aberration effect based on flow (from B)
    float aberration = abs(uv.x - 0.5) * 3.0;
    final_color.r += aberration * 0.05;
    final_color.g -= aberration * 0.08;

    // Apply noise and contrast boost (from B)
    final_color = mix(final_color, vec3(0.02, 0.10, 0.01), noise_factor * 0.7);

    // Final intensity adjustment
    final_color *= 1.8;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
