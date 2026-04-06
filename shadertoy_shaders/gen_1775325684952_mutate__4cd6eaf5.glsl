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

vec2 flow(vec2 uv, float t)
{
    vec2 offset = vec2(
        sin(uv.x * 15.0 + t * 1.2),
        cos(uv.y * 10.0 + t * 0.8) * 0.7
    );
    return uv * 1.5 + offset;
}

vec3 palette(float t)
{
    float c1 = 0.5 + 0.5 * sin(t * 0.6 + iTime * 0.4);
    float c2 = 0.5 + 0.5 * cos(t * 0.7 + iTime * 0.5);
    float c3 = 0.5 + 0.5 * sin(t * 0.5 + iTime * 0.8);
    return vec3(c1, c2, c3);
}

vec2 waveX(vec2 uv)
{
    float phase = uv.x * 20.0 + uv.y * 15.0 + iTime * 2.0;
    return vec2(
        sin(phase * 0.5),
        cos(phase * 0.7)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Flow and primary distortion
    uv = flow(uv, iTime * 0.8);

    vec2 wave = waveX(uv);

    // Time-based rotation and complex shear
    float angle = uv.x * 6.0 + uv.y * 4.0 + iTime * 2.5;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv *= rotationMatrix;

    // Secondary dynamic warping
    vec2 warped_uv = flow(uv, iTime * 0.5);

    // Modulation factor based on warped position
    float t = (warped_uv.x * 1.5 + warped_uv.y * 1.0) * 10.0 + iTime * 1.2;
    vec3 base_color = palette(t);

    // Advanced color generation based on noise and time
    float noise_factor = sin(warped_uv.x * 5.0 + iTime * 3.0) * cos(warped_uv.y * 6.0 + iTime * 2.0);

    // Mix the palette with high contrast modulation
    vec3 final_color = base_color * (1.0 + noise_factor * 0.5);

    // Apply a strong positional shift based on the wave
    final_color.r += wave.x * 0.5;
    final_color.b += wave.y * 0.3;

    // Final exposure and output
    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
