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
    return vec2(sin(uv.x * 8.0 + iTime * 1.2), cos(uv.y * 9.0 - iTime * 0.9));
}

vec2 waveA(vec2 uv)
{
    return uv * 2.5 + vec2(
        sin(uv.x * 5.0 + iTime * 0.8) * 0.2,
        cos(uv.y * 6.0 - iTime * 0.7) * 0.25
    );
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 ripple(vec2 uv) {
    float t = iTime * 2.0;
    float r = length(uv);
    float phase = r * 10.0 + t * 1.5;
    return uv * (1.0 + 0.1 * sin(phase)) + vec2(sin(phase * 0.5), cos(phase * 0.7));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Normalize UVs (Shader B style)
    uv = uv * 2.0 - 1.0;

    // Base distortion scaling based on time and space
    float flow_scale = 1.0 + sin(iTime * 1.5) * 0.5;
    uv *= flow_scale;

    // Complex spatial deformation based on polar coordinates and time (Shader B style)
    float angle = atan(uv.y, uv.x) * 3.0 + iTime * 0.5;
    float radius = length(uv);

    vec2 rotated_uv = rotate(uv, angle);

    // Apply ripple transformation (Shader B style)
    vec2 distorted_uv = ripple(rotated_uv);

    // Apply wave structure (Shader A style)
    vec2 wave_offset = waveB(distorted_uv);
    distorted_uv += wave_offset;

    // Introduce radial scaling and deformation (Shader B style)
    distorted_uv *= (1.0 + radius * 0.5);

    // Introduce shearing based on the distance from the center (Shader B style)
    float shear = radius * 10.0;
    distorted_uv.x += shear;

    // Stronger time-based fluctuation based on polar coordinates (Shader B style)
    distorted_uv.x += sin(iTime * 2.0) * 0.3;
    distorted_uv.y += cos(iTime * 1.8) * 0.3;

    // Final color mapping based on the distorted coordinates
    float t = (distorted_uv.x * 10.0 + distorted_uv.y * 15.0) * 0.5 + iTime;
    vec3 col = palette(t);

    // Introduce a final chromatic shift based on the magnitude (Shader B style)
    float color_shift = sin(radius * 15.0 + iTime * 3.0) * 0.5;

    col.r = mix(col.r, 0.9 + color_shift * 0.3, 0.6);
    col.g = mix(col.g, 0.7 + color_shift * 0.4, 0.5);
    col.b = mix(col.b, 0.5 + color_shift * 0.2, 0.7);

    // Add high frequency detail using modulation of flow (Shader B style complexity)
    col.r += sin(distorted_uv.x * 60.0 + iTime * 4.0) * 0.15;
    col.g += cos(distorted_uv.y * 40.0 + iTime * 3.5) * 0.1;
    col.b += sin(distorted_uv.x * 80.0 + iTime * 2.5) * 0.15;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
