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

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 wave(vec2 uv) {
    float t = iTime * 1.5;
    return vec2(sin(uv.x * 8.0 + t * 2.0), cos(uv.y * 7.0 - t * 3.0));
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5) * 1.2;
    float g = 0.5 + 0.4 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec3 colorForLayer(float i, float c) {
    float r = 0.5 + 0.5 * sin(i * 2.0 + iTime * 1.2);
    float g = 0.5 + 0.5 * cos(i * 3.0 - iTime * 0.8);
    float b = 0.2 + i + c * 0.5;
    return vec3(r * 0.8 + c * 0.2, g * 1.1, b + 0.3);
}

vec2 fractal(vec2 uv) {
    float t = iTime;
    uv.x += sin(uv.y * 360.0 + t * 10.0) * 0.02;
    uv.y += cos(uv.x * 40.0 + t * 5.0) * 0.02;
    return uv;
}

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 10.0 - 5.0; 

    // Setup base transformations
    uv = fractal(uv);

    // Calculate primary wave pattern
    vec2 w = wave(uv);

    // Input for position normalization
    vec2 base_pos = uv * 3.0 + 1.0;

    // Segment definition for distortion depth variation
    float density = 15.0 + sin(base_pos.x * 25.0) * 6.0; 

    // Layered field modulation - modified interaction
    float l1r = sin(base_pos.x * density + iTime * 1.8) * 0.6;
    float l1g = cos(base_pos.y * density * 1.2 - iTime * 0.7);

    float l2r = sin(base_pos.y * 60.0 + iTime * 2.5) * iTime * 0.4;
    float l2g = 1.0 - l1g * 0.7 + l2r * 0.3; 

    // Base tone driven by noise applied differently
    vec2 noise_uv = uv * 50.0 + iTime * 6.0;
    float base_t = noise(noise_uv * 10.0).r * 0.5 + 0.5;

    // Color compounding based on complexity using the layered function
    vec3 c1 = colorForLayer(base_pos.x * 20.0, l1r);
    vec3 c2 = colorForLayer(base_pos.y * 15.0, l2g);
    vec3 c3 = vec3(base_t * 0.5, l2g * 0.9, l1g * 1.1); // Adjusted base_t influence

    // Blend intermediate lights towards the final composite
    float blend_factor = sin(iTime * 1.1) * 0.3;
    vec3 final_color = mix(c1, c3, blend_factor) * 0.6;
    final_color = mix(final_color, c2, base_pos.x * 1.2);
    final_color = mix(final_color, vec3(0.0, 0.1, 0.2), l2r * 2.0); // Increased influence of blue layer

    // Final spectral shift application - focusing on contrast
    float freq_shift = sin(uv.x * 25.0 + uv.y * 15.0) * 3.0;
    final_color.r = pow(l1r * 1.2 + freq_shift * 0.3, 1.6);

    // Modified G channel interaction based on wave and noise
    final_color.g = mix(cos(uv.x * 10.0 + w.x * 5.0), l2g * 0.5, 0.5);

    // Introduce feedback loop for blue channel
    final_color.b = 0.05 + l1g * 0.5 + noise(base_pos * 8.0 + iTime * 3.0 + uv.x * 5.0).x * 0.35;

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
