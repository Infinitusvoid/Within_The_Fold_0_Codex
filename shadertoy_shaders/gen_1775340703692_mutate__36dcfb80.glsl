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
    return vec2(sin(uv.x * 10.0 + iTime * 2.0), cos(uv.y * 11.0 - iTime * 1.5));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 1.2 + iTime * 0.7);
    float g = 0.4 + 0.6 * sin(t * 0.9 + iTime * 0.5);
    float b = 0.15 + 0.5 * cos(t * 1.8 - iTime * 0.3);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 3.5 + vec2(
        sin(uv.x * 7.0 + iTime * 1.0) * 0.1,
        cos(uv.y * 8.0 - iTime * 0.5) * 0.15
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Base wave structure
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow based on complex angle
    float angle = iTime * 0.3 + uv.x * 8.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure
    warped_uv = waveA(warped_uv);

    // Introduce stronger dynamic spatial flow
    float flow_x = iTime * 0.7 + uv.x * 5.0;
    float flow_y = iTime * 0.5 + uv.y * 6.0;

    // Use flow for positional shifting, introducing stronger distortion
    warped_uv.x += sin(flow_x * 1.8) * 0.15;
    warped_uv.y += cos(flow_y * 1.4) * 0.15;

    // Generate dynamic value based on complex interaction
    float t = sin(warped_uv.x * 7.0 + iTime * 1.8) + cos(warped_uv.y * 5.0 + iTime * 0.8);

    vec3 col1 = palette(t * 2.0);

    // Introduce depth based on phase shift
    float phase_shift = sin(warped_uv.x * 7.0 + iTime * 4.0) * 0.6;
    vec3 col2 = palette(phase_shift + warped_uv.y * 0.25);

    // Blend colors based on phase and flow interaction
    vec3 final_color = mix(col1, col2, phase_shift * 0.9 + flow_x * 0.25);

    // Introduce high-frequency noise based on complex movement
    float noise_factor = sin(warped_uv.x * 20.0 + iTime * 3.5) * cos(warped_uv.y * 12.0 - iTime * 1.0);

    // Introduce a swirl distortion based on time
    vec2 swirl = vec2(sin(iTime * 3.0), cos(iTime * 3.0));
    warped_uv = mix(warped_uv, warped_uv * swirl, 0.1);

    // Apply chromatic aberration effect based on flow
    float aberration = abs(uv.x - 0.5) * 4.0;
    final_color.r += aberration * 0.18;
    final_color.g -= aberration * 0.12;
    final_color.b += aberration * 0.15;

    // Apply noise and contrast boost
    final_color = mix(final_color, vec3(0.05, 0.15, 0.02), noise_factor * 0.8);

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
