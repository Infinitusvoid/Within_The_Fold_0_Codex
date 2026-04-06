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
    float t = iTime * 0.7;
    // Enhanced wave structure focusing on different spatial relationships
    float w1 = sin(uv.x * 10.0 + t * 1.5) * 0.5;
    float w2 = cos(uv.y * 8.0 + t * 1.0) * 0.4;
    float w3 = sin(length(uv) * 3.0 + t * 2.0) * 0.3;
    return vec2(w1 * 0.6 + w3 * 0.4, w2 * 0.6 + w3 * 0.4);
}

vec3 palette(float t) {
    // A palette based on hyperbolic functions and accumulated time
    float a = fract(sin(t * 3.14159) * 0.5 + 0.5);
    float b = (cos(t * 2.0) * 0.5 + 0.5) * (1.0 - abs(sin(t * 1.5)));
    float c = abs(sin(t * 4.0)) * 0.6 + 0.4;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Base flow and pulsing movement
    float flow_speed = 2.0 + sin(iTime * 0.4) * 0.6;
    uv *= flow_speed;

    // 2. Complex rotational field
    float angle_base = uv.x * 6.0 + iTime * 0.6;
    float angle_spin = iTime * 1.8;

    // 3. Apply rotation
    uv = rotate(uv, angle_base);
    uv = rotate(uv, angle_spin);

    // 4. Radial distortion based on complex distance
    float dist = length(uv);
    // Use a sharper, more defined radial pull
    float pull = 1.0 - pow(dist, 1.5) * 1.8;
    uv *= pull;

    // 5. Interaction with the wave field
    uv = wave(uv * 5.0);

    // 6. Color mapping based on interaction fields
    // Use a combination of coordinates and time for complexity
    float t = (uv.x * 3.0 + uv.y * 3.0) * 1.5 + iTime * 1.0;
    vec3 col = palette(t);

    // 7. Introducing a radial gradient modulation
    float radial_fade = 1.0 - smoothstep(0.0, 1.0, dist * 2.0);
    col *= (0.5 + radial_fade * 0.5);

    // 8. Final depth/color shift based on rotation
    float angle = atan(uv.y, uv.x);
    float phase_shift = sin(angle * 5.0 + iTime * 0.8);

    // Mix color with a complementary hue based on rotation phase
    vec3 complementary = vec3(1.0 - phase_shift, phase_shift * 1.5, 0.5);
    col = mix(col, complementary, phase_shift * 0.7);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
