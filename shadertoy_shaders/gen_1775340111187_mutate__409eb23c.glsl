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
    float t = iTime * 0.8;
    // Modifying wave to emphasize complex swirling patterns and parallax
    float w1 = sin(uv.x * 12.0 + t * 1.5) * 0.4;
    float w2 = cos(uv.y * 10.0 + t * 1.2) * 0.3;
    float w3 = sin(length(uv) * 5.0 + t * 2.0) * 0.2;
    return vec2(w1 * 0.8 + w3 * 0.2, w2 * 0.6 + w3 * 0.4);
}

vec3 palette(float t) {
    // A highly layered, psychedelic palette
    float a = sin(t * 0.4) * 0.6 + 0.4;
    float b = cos(t * 0.6) * 0.6 + 0.4;
    float c = sin(t * 1.2) * 0.5 + 0.5;
    return vec3(a, b, c);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // 1. Primary motion and flow
    float flow_speed = 4.0 + sin(iTime * 0.1) * 0.5;
    uv *= flow_speed;

    // 2. Multi-axis rotation and shear
    float angle1 = uv.x * 10.0 + iTime * 0.4;
    float angle2 = uv.y * 8.0 + iTime * 0.3;

    mat2 rot1 = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    mat2 rot2 = mat2(cos(angle2), -sin(angle2), sin(angle2), cos(angle2));

    uv = rot1 * uv;
    uv = rot2 * uv;

    // 3. Vortex focusing (pulling towards the center with dynamic strength)
    vec2 center = vec2(0.0);
    float dist = length(uv);
    float pull_strength = 2.0;
    // Stronger center pull, modulated by time
    uv = uv * (1.0 - dist * pull_strength * 0.4 + 0.15);

    // 4. Wave distortion input
    uv = wave(uv);

    // 5. Color mapping based on combined distortion
    float t = (uv.x * 11.0 + uv.y * 11.0) * 0.5 + iTime * 2.5;
    vec3 col = palette(t);

    // 6. Radial energy mapping (Focusing on magnitude)
    float r = length(uv);
    float energy = 0.5 + 0.5 * sin(r * 6.0 + iTime * 3.0);
    col *= energy;

    // 7. Introduce chromatic shift based on accumulated phase
    float angle = atan(uv.y, uv.x);
    float phase_shift = angle * 12.0 + iTime * 2.8;

    col.r = sin(phase_shift * 1.1) * 0.5 + 0.5;
    col.g = cos(phase_shift * 0.7) * 0.5 + 0.5;
    col.b = sin(phase_shift * 1.3) * 0.5 + 0.5;

    // 8. Introduce a final subtle layer of gradient based on coordinates
    float depth = (uv.x + uv.y) * 0.5;
    col.r = mix(col.r, 0.1, depth * 0.5);
    col.g = mix(col.g, 0.2, depth * 0.3);
    col.b = mix(col.b, 0.3, depth * 0.6);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
