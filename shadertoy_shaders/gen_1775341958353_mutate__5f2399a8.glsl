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
    return vec2(sin(uv.x * 15.0 + iTime * 3.0), cos(uv.y * 12.0 - iTime * 2.5));
}

vec3 palette(float t)
{
    float r = 0.15 + 0.5 * sin(t * 1.2 + iTime * 1.8);
    float g = 0.5 + 0.4 * cos(t * 0.9 + iTime * 1.1);
    float b = 0.3 + 0.6 * sin(t * 2.5 - iTime * 0.5);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 3.0 + vec2(
        sin(uv.x * 8.0 + iTime * 0.9) * 0.5,
        cos(uv.y * 10.0 - iTime * 1.3) * 0.4
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Primary wave structure
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow
    float angle = iTime * 0.7 + uv.x * 4.0;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Secondary wave structure
    warped_uv = waveA(warped_uv);

    // Introduce flow and displacement based on time
    vec2 flow = vec2(iTime * 0.8, iTime * 1.2);
    warped_uv += sin(warped_uv.x * 5.0 + flow.x) * 0.1;
    warped_uv += cos(warped_uv.y * 6.0 + flow.y) * 0.08;

    // Generate dynamic value based on highly modulated coordinates
    float t = sin(warped_uv.x * 8.0 + iTime * 3.0) * 0.5 + cos(warped_uv.y * 7.0 + iTime * 2.0);

    vec3 col1 = palette(t * 1.8);

    // Introduce secondary color based on high frequency shift
    float phase_shift = sin(warped_uv.x * 12.0 + iTime * 5.0) * 0.4;
    vec3 col2 = palette(phase_shift * 0.8 + warped_uv.y * 0.2);

    // Blend colors dynamically based on flow interaction
    float blend_factor = sin(warped_uv.x * 3.0) * 0.5 + cos(warped_uv.y * 3.0) * 0.5;
    vec3 final_color = mix(col1, col2, blend_factor * 1.2);

    // Introduce high-frequency noise and texture distortion
    float noise_scale = 20.0;
    float noise_factor = sin(warped_uv.x * noise_scale + iTime * 5.0) * cos(warped_uv.y * 11.0 - iTime * 1.0);

    // Mix in dark accents based on noise
    final_color = mix(final_color, vec3(0.05, 0.03, 0.08), noise_factor * 0.7);

    // Apply subtle ambient lighting shift
    float ambient_shift = sin(iTime * 0.5) * 0.1;
    final_color *= (1.5 + ambient_shift);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
