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
    return vec2(sin(uv.x * 12.0 + iTime * 1.5), cos(uv.y * 10.0 - iTime * 1.8));
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
    return uv * 4.0 + vec2(
        sin(uv.x * 9.0 + iTime * 1.1) * 0.2,
        cos(uv.y * 7.0 - iTime * 0.9) * 0.1
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial wave structure based on waveB
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow based on complex angle
    float angle = iTime * 0.4 + uv.x * 5.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure based on waveA
    warped_uv = waveA(warped_uv);

    // Apply non-linear spatial flow
    float flow_x = iTime * 0.8 + uv.x * 3.0;
    float flow_y = iTime * 0.6 + uv.y * 4.0;

    // Use flow for positional shifting, introducing complex distortion
    vec2 flow_distortion = vec2(
        sin(flow_x * 2.5) * 0.15,
        cos(flow_y * 2.0) * 0.1
    );
    warped_uv += flow_distortion;

    // Generate dynamic value based on phase interaction
    float t = sin(warped_uv.x * 7.5 + iTime * 2.0) + cos(warped_uv.y * 6.0 + iTime * 1.0);

    vec3 col1 = palette(t * 1.5);

    // Introduce a second color based on flow
    float phase_shift = sin(warped_uv.x * 10.0 + iTime * 5.0) * 0.5;
    vec3 col2 = palette(phase_shift + warped_uv.y * 0.3);

    // Blend colors based on the flow interaction
    vec3 final_color = mix(col1, col2, phase_shift * 0.7 + flow_x * 0.1);

    // Introduce high frequency noise based on warped coordinates
    float noise_factor = sin(warped_uv.x * 35.0 + iTime * 3.0) * cos(warped_uv.y * 15.0 - iTime * 1.5);

    // Apply chromatic aberration based on spatial position
    float aberration = abs(uv.x - 0.5) * 4.0;
    final_color.r += aberration * 0.1;
    final_color.g -= aberration * 0.05;
    final_color.b += aberration * 0.15;

    // Mix with a dark ambient color based on noise
    final_color = mix(final_color, vec3(0.05, 0.05, 0.1), noise_factor * 0.8);

    // Final intensity and contrast adjustment
    final_color = pow(final_color, vec3(1.1));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
