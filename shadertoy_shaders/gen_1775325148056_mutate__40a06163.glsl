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

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.3 + 0.7;
    float c = cos(t * 0.8) * 0.4 + 0.6;
    return uv * vec2(s, c) + vec2(sin(uv.x * 15.0 + t * 0.5), cos(uv.y * 20.0 - t * 0.6));
}

vec2 wave(vec2 uv)
{
    return vec2(sin(uv.x * 4.0 + iTime * 0.3), cos(uv.y * 2.0 + iTime * 0.6));
}

vec3 palette(float t)
{
    return vec3(0.5 + 0.5 * cos(t + iTime * 0.1), 0.5 + 0.5 * sin(t + iTime * 0.2), 0.5 + 0.5 * cos(t + iTime * 0.3));
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // Base distortion setup
    vec2 warped_uv = wave(uv);
    vec2 final_uv = distort(warped_uv, iTime * 0.5);

    // Dynamic scaling based on time and coordinates
    float scale_factor = 1.0 + 0.5 * sin(iTime * 1.5);
    final_uv *= scale_factor;

    // Introduce a subtle wave modulation based on distance from center
    float dist_center = length(final_uv);
    final_uv += 0.1 * sin(dist_center * 10.0 + iTime * 0.8);

    // Rotation logic
    float angle = iTime * 0.5 + final_uv.x * 1.0 + final_uv.y * 0.8;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    final_uv = rotate(final_uv, angle);

    // Color and depth based on flow direction
    float flow = 1.0 + abs(final_uv.x) * 2.0;

    // Calculate color based on complex interaction
    float t = final_uv.x * final_uv.y * 5.0 + iTime * 0.6;
    vec3 base_color = palette(t);

    // R component: influenced by flow and rotation angle
    float r = base_color.r * flow * cos(final_uv.y * 10.0 + iTime * 0.2);

    // G component: influenced by spatial displacement and time
    float g = base_color.g * (0.5 + 0.5 * sin(iTime * 3.0 + final_uv.x * 5.0));

    // B component: based on inverse flow and contrast
    float b = (1.0 - flow) * 0.5 + 0.5 * sin(final_uv.y * 8.0);

    // Final composition using a specific pattern shift
    vec3 col = vec3(r, g, b);

    // Introduce a final saturation/contrast boost based on time and position
    float contrast_shift = 1.0 + sin(iTime * 2.0) * 0.3;
    col = mix(col, vec3(0.0, 0.5, 1.0), contrast_shift * (0.5 + final_uv.x * 0.5));

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
