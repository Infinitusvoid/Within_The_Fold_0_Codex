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
        sin(uv.x * 5.0 + uv.y * 2.0 + t),
        cos(uv.x * 3.0 - uv.y * 1.5 + t * 0.7)
    );
}

vec3 palette(float t) {
    return vec3(0.5 + 0.5*sin(t + iTime * 0.1), 0.5 + 0.5*sin(t + iTime * 0.2), 0.5 + 0.5*cos(t + iTime * 0.3));
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.7) * 0.3 + 0.7;
    float c = cos(t * 0.8) * 0.4 + 0.6;
    return uv * vec2(s, c) + vec2(sin(uv.x * 15.0 + t * 0.5), cos(uv.y * 20.0 - t * 0.6));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;

    // 1. Initial Setup and Warping (Combining A's warping and B's wave)
    vec2 warped_uv = wave(uv);
    vec2 final_uv = distort(warped_uv, iTime * 0.5);

    // 2. Rotation and Phase Shift (From A)
    float angle1 = sin(iTime * 0.3) + final_uv.x * final_uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    final_uv *= rotationMatrix;

    // 3. Positional modulation
    final_uv += vec2(
        sin(final_uv.x * 1.2 + iTime * 0.7) * 0.2,
        cos(final_uv.y * 1.5 + iTime * 0.6) * 0.3
    );

    // 4. Palette Input calculation (Using B's polar structure)
    float r = length(final_uv);
    float angle = atan(final_uv.y, final_uv.x);
    float time_factor = iTime * 0.5;

    // 5. Calculate complex inputs based on polar coordinates
    float t1 = r * 10.0 + time_factor * 0.5;
    float t2 = angle * 3.0 + time_factor * 0.3;
    float t3 = r * 5.0 + angle * 2.0 + time_factor * 1.5;

    // 6. Coloring based on combined patterns (Mixing A's complexity and B's smoothing)

    // R component: Based on radial pattern and palette (A's approach)
    float r_pat = sin(t1) * 0.5 + 0.5;
    vec3 col = palette(t1);
    col.r = mix(0.8, 0.2, r_pat) * col.r;

    // G component: Based on angular pattern and palette (A's approach)
    float a_pat = cos(t2) * 0.5 + 0.5;
    col.g = mix(0.8, 0.2, a_pat) * col.g;

    // B component: Combined pattern (B's approach)
    float combined = sin(t3);
    col.b = abs(combined) * 0.7 + 0.1;
    col.b *= palette(t3).b * 1.2;

    // Final subtle adjustment based on initial UV complexity
    col += sin(final_uv.x * 0.5 + iTime) * 0.1;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
