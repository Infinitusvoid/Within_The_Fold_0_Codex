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

vec2 wave(vec2 uv) {
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 6.0 + t * 0.5),
        cos(uv.y * 4.0 - t * 0.6)
    );
}

vec3 palette(float t) {
    vec3 c = vec3(0.5 + 0.5*sin(t * 1.5 + iTime), 0.5 + 0.5*cos(t * 2.0 + iTime * 0.5), 0.5 + 0.5*sin(t * 2.5 + iTime * 0.7));
    return c;
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.6) * 0.5 + 0.5;
    float c = cos(t * 0.8) * 0.5 + 0.5;
    return uv * vec2(s, c) + vec2(sin(uv.x * 30.0 + t * 1.0), cos(uv.y * 40.0 - t * 0.3));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Initial Warping
    vec2 warped_uv = wave(uv);
    vec2 final_uv = distort(warped_uv, iTime * 0.8);

    // 2. Polar Flow and Rotation
    float flow_angle = atan(final_uv.y, final_uv.x);
    float flow_dist = length(final_uv);

    float angle1 = flow_angle * 1.5 + iTime * 0.7;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    final_uv *= rotationMatrix;

    // 3. Radial Ripple and Refraction
    float ripple = flow_dist * 5.0;
    float refractive_factor = 1.0 + 0.2 * sin(ripple * 1.2 + iTime);
    final_uv *= refractive_factor;

    // 4. Detail and Offset
    final_uv += vec2(
        sin(final_uv.x * 10.0 + iTime * 2.0) * 0.1,
        cos(final_uv.y * 15.0 + iTime * 1.5) * 0.05
    );

    // 5. Palette Input calculation
    float t1 = flow_dist * 3.0 + iTime * 1.2;
    float t2 = flow_angle * 5.0 + iTime * 2.5;
    float t3 = flow_dist * 6.0 + flow_angle * 3.0;

    // 6. Coloring based on combined patterns

    vec3 col = palette(t1);

    // R component: Based on radial interaction
    float r_pat = sin(t3 * 0.8) * 0.4 + 0.6;
    col.r = mix(0.1, 0.9, r_pat);

    // G component: Based on angular pattern
    float a_pat = cos(t2) * 0.5 + 0.5;
    col.g = mix(0.3, 1.0, a_pat);

    // B component: Focused on distortion and time
    float b_pat = sin(t1 * 1.1) * 0.5 + 0.5;
    col.b = b_pat * 0.8 + 0.2;
    col.b *= palette(t3).b * 1.2;

    // Final contrast adjustment based on final UV position
    float final_contrast = sin(final_uv.x * 1.5 + iTime * 1.0) * 0.2;
    col += final_contrast;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
