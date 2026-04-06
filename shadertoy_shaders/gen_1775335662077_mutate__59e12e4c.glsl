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

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 ripple(vec2 uv) {
    float t = iTime * 1.5;
    float r = length(uv);
    float phase = r * 5.0 + t * 2.0;
    return uv * (1.0 + 0.1 * sin(phase)) + vec2(sin(phase * 0.4), cos(phase * 0.6));
}

vec3 palette(float t) {
    vec3 c = vec3(
        0.1 + 0.9*sin(t * 1.2 + iTime * 0.3),
        0.1 + 0.9*cos(t * 1.1 + iTime * 0.1),
        0.1 + 0.8*sin(t * 0.8 + iTime * 0.2)
    );
    return c * 1.2 + 0.05; // Stronger and brighter palette
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base flow and time shift
    float flow_speed = 1.5 + sin(iTime * 0.8) * 0.5;
    uv *= flow_speed;

    // Complex spatial deformation based on polar coordinates and time
    float angle = atan(uv.y, uv.x) * 5.0 + iTime * 0.7;
    float radius = length(uv);

    vec2 rotated_uv = rotate(uv, angle);

    // Apply ripple transformation, dependent on radius
    vec2 distorted_uv = ripple(rotated_uv);

    // Introduce radial pulsing and scaling
    float pulse = 1.0 + 0.5 * sin(radius * 3.0 + iTime * 4.0);
    distorted_uv *= pulse;

    // Introduce vortex shearing based on angle
    float vortex_shear = radius * 8.0;
    distorted_uv.x += vortex_shear * sin(angle * 0.5);
    distorted_uv.y += vortex_shear * cos(angle * 0.5);

    // Time-based flow shift
    distorted_uv.x += sin(iTime * 3.0) * 0.2;
    distorted_uv.y += cos(iTime * 2.5) * 0.2;

    // Final color mapping
    // Use a combination of transformed coordinates for coloring
    float color_t = (distorted_uv.x * 8.0 + distorted_uv.y * 12.0 + radius * 5.0) * 0.4 + iTime;
    vec3 col = palette(color_t);

    // Introduce chromatic modulation based on flow magnitude
    float chromatic_shift = sin(radius * 20.0 + iTime * 5.0) * 0.4;

    col.r = mix(col.r, 1.0 + chromatic_shift * 0.5, 0.7);
    col.g = mix(col.g, 0.8 + chromatic_shift * 0.3, 0.6);
    col.b = mix(col.b, 0.6 + chromatic_shift * 0.2, 0.5);

    // Add high frequency noise based on flow
    col.r += sin(distorted_uv.x * 80.0 + iTime * 5.0) * 0.2;
    col.g += cos(distorted_uv.y * 40.0 + iTime * 4.5) * 0.2;
    col.b += sin(distorted_uv.x * 100.0 + iTime * 3.0) * 0.15;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
