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
    // Modifying wave to emphasize higher frequencies based on distance
    float w1 = sin(uv.x * 8.0 + t * 0.5) * 0.6;
    float w2 = cos(uv.y * 5.0 + t * 0.3) * 0.4;
    float w3 = sin(length(uv) * 2.0 + t * 1.0) * 0.3;
    return vec2(w1 + w3 * 0.5, w2 + w3 * 0.5);
}

vec3 palette(float t) {
    // A palette based on layered trigonometric functions for high contrast
    float a = sin(t * 0.5) * 0.5 + 0.5;
    float b = cos(t * 0.7) * 0.5 + 0.5;
    float c = abs(sin(t * 1.2)) * 0.8 + 0.2;
    return vec3(a, b, c);
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord/iResolution.xy;
    uv = uv * 2.0 - 1.0;

    // --- Shader A components: Rotation and Wave Distortion ---

    // 1. Primary spatial scaling and animation
    float flow_speed = 1.5 + sin(iTime * 0.5) * 0.5;
    uv *= flow_speed;

    // 2. Rotational offset based on screen position
    float angle1 = uv.x * 5.0 + iTime * 0.4;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    // 3. Apply rotation based on time for overall swirl
    float angle2 = iTime * 0.7;
    uv = rotate(uv, angle2);

    // 4. Vortex distortion (pulling towards the center based on distance)
    vec2 center = vec2(0.0);
    float dist = length(uv);
    uv = uv * (1.0 - dist * 0.5);

    // 5. Wave distortion input
    uv = wave(uv);

    // --- Shader B components: Polar Coordinates and Radial Flow ---

    vec2 center_uv = vec2(0.5);

    // Calculate polar coordinates relative to the center
    vec2 offset = uv - center_uv;
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // Dynamic flow and phase based on time and position
    float flow_speed_b = 1.5 + iTime * 1.0;

    // Phase calculation, incorporating angular movement
    float phase = a * 15.0 + r * 4.0 + iTime * 0.7 + a * 5.0;

    float f = sin(phase * flow_speed_b);

    // Ripple effect: introduce time-based distortion to the radial coordinate, modulated by angle
    float ripple = sin(r * 10.0 + iTime * 4.0) * 0.1 * (1.0 + abs(a));

    // Use the cosine of the distance for falloff
    float dist_falloff = exp(-r * r * 1.5);

    // Introduce a layer based on the frame number and flow
    float frame_shift = sin(iFrame * 0.1) * 0.2;

    // Modulate the input to the palette based on the ripple and flow, emphasizing angular movement
    float palette_input = r * 1.8 + frame_shift + ripple * 0.5;

    // Sharper contrast based on the flow state
    float m = smoothstep(0.25, 0.15, abs(f));

    // Use the modified flow and falloff to drive the palette
    vec3 col = pal(palette_input) * m * dist_falloff * (1.0 + r * 0.7);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
