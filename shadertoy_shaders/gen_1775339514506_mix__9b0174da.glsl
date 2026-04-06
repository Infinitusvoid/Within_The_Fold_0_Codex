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
    float t = iTime * 2.0;
    float r = length(uv);
    float phase = r * 10.0 + t * 1.5;
    return uv * (1.0 + 0.1 * sin(phase)) + vec2(sin(phase * 0.5), cos(phase * 0.7));
}

vec3 palette(float t) {
    vec3 c = vec3(0.1 + 0.9*sin(t * 1.5 + iTime * 0.2), 0.1 + 0.9*cos(t * 1.2 + iTime * 0.1), 0.1 + 0.8*sin(t * 0.8 + iTime * 0.3));
    return c * 0.8 + 0.1; // Brighten and shift the palette
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0; // Normalize to [-1, 1]

    // --- Core Deformation (From Shader A) ---

    // Base distortion scaling based on time and space
    float flow_scale = 1.0 + sin(iTime * 1.5) * 0.5;
    uv *= flow_scale;

    // Complex spatial deformation based on polar coordinates and time
    float angle = atan(uv.y, uv.x) * 3.0 + iTime * 0.5;
    float radius = length(uv);

    vec2 rotated_uv = rotate(uv, angle);

    // Apply ripple transformation
    vec2 distorted_uv = ripple(rotated_uv);

    // Introduce radial scaling and deformation
    distorted_uv *= (1.0 + radius * 0.5);

    // Introduce shearing based on the distance from the center
    float shear = radius * 10.0;
    distorted_uv.x += shear;

    // Stronger time-based fluctuation based on polar coordinates
    distorted_uv.x += sin(iTime * 2.0) * 0.3;
    distorted_uv.y += cos(iTime * 1.8) * 0.3;

    // --- Coloring and Falloff (From Shader B) ---

    // Calculate dynamic flow phase
    float flow_speed = 2.0 + iTime * 1.5;
    float phase = atan(distorted_uv.y, distorted_uv.x) * 10.0 + length(distorted_uv) * 5.0 + iTime * 0.5;

    float f = sin(phase);

    // Use the cosine of the distance for falloff
    float dist_falloff = exp(-length(distorted_uv) * length(distorted_uv) * 0.5);

    // Introduce a layer based on the frame number
    float frame_shift = sin(iFrame * 0.1) * 0.1;

    float m = smoothstep(0.25, 0.0, abs(f + frame_shift));

    // Use the flow to drive the palette input (Using A's palette structure)
    vec3 col = palette(length(distorted_uv) * 1.5 + frame_shift) * m * dist_falloff;

    // Introduce a final chromatic shift based on the magnitude
    float color_shift = sin(length(distorted_uv) * 15.0 + iTime * 3.0) * 0.5;

    col.r = mix(col.r, 0.9 + color_shift * 0.3, 0.6);
    col.g = mix(col.g, 0.7 + color_shift * 0.4, 0.5);
    col.b = mix(col.b, 0.5 + color_shift * 0.2, 0.7);

    // Add high frequency detail using modulation of flow
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
