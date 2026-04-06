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
    float t = iTime * 0.6;
    // Introducing sharper, faster oscillations
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.6;
    float w2 = cos(uv.y * 8.0 + t * 2.0) * 0.4;
    float w3 = sin(length(uv) * 3.0 + t * 0.5) * 0.2;
    return vec2(w1 + w3 * 0.4, w2 + w3 * 0.4);
}

vec3 palette(float t) {
    // A high-contrast, psychedelic palette using smooth steps
    float a = fract(sin(t * 1.5 + iTime * 0.1) * 3.0);
    float b = fract(sin(t * 2.0 + iTime * 0.2) * 3.0);
    float c = fract(sin(t * 3.0 + iTime * 0.3) * 3.0);
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Initial scaling and time distortion
    float scale = 1.5 + sin(iTime * 1.5) * 0.3;
    uv *= scale;

    // 2. Complex rotation based on UV and time
    float angle1 = sin(iTime * 0.5) + uv.x * uv.y * 3.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    // 3. Second rotation, emphasizing cyclical movement
    float angle2 = iTime * 1.2 + atan(uv.y, uv.x) * 0.8;
    uv = rotate(uv, angle2);

    // 4. Introduce a gravitational pull distortion (centralized vortex)
    vec2 center = vec2(0.0);
    float dist = length(uv);

    // Apply inverse distance distortion
    uv = uv / (dist * 0.5 + 0.5); 
    uv = uv * 2.0 - 1.0; // Remap back to [-1, 1]

    // 5. Introduce anisotropic stretching based on time
    float stretch_factor = 1.0 + sin(iTime * 2.0) * 0.4;
    uv.x *= stretch_factor;
    uv.y *= stretch_factor;

    // 6. Base distortion mixing (using a different wave pattern)
    vec2 distort = vec2(
        sin(uv.x * 12.0 + iTime * 1.0) * 0.5,
        cos(uv.y * 10.0 + iTime * 1.1) * 0.5
    );
    uv += distort * 0.2;

    uv = wave(uv);

    // 7. Color mapping using a shift based on UV magnitude
    float t = (uv.x * 6.0 + uv.y * 6.0) * 0.7 + iTime * 1.0;
    vec3 col = palette(t);

    // 8. Radial intensity manipulation
    float intensity_r = 0.5 + 0.4 * cos(length(uv) * 15.0 + iTime * 1.2);
    col.r = mix(col.r, intensity_r, 0.8);

    // 9. Enhanced G channel complexity using trigonometric mixing
    float angle = atan(uv.y, uv.x);
    col.g = sin(angle * 8.0 + iTime * 0.7) * 0.5 + 0.5;

    // 10. Modify B channel based on contrast of coordinates
    float contrast_val = abs(uv.x * 2.0 - uv.y * 2.0);
    float contrast = smoothstep(0.0, 1.0, contrast_val * 2.0);
    col.b = 0.1 + contrast * 0.9;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
