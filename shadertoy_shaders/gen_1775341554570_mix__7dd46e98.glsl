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

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    vec2 center_uv = vec2(0.5);

    // Calculate polar coordinates relative to the center
    vec2 offset = uv - center_uv;
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // --- Influence from Shader A: Grid Pattern ---
    // Use the grid structure from A, but modulated by time and radial distance
    float x_coord = a / 3.14159;
    float y_flow = 0.2 / max(r, 0.001) + iTime * 1.5;

    float grid_pattern = 0.5 + 0.5 * sin(20.0 * y_flow + 10.0 * x_coord);

    // --- Influence from Shader B: Flow, Ripple, and Noise ---

    // Dynamic flow and phase based on time and position
    float flow_speed = 1.5 + iTime * 1.0;

    // Phase calculation, incorporating angular movement
    float phase = a * 15.0 + r * 4.0 + iTime * 0.7 + a * 5.0;

    float f = sin(phase * flow_speed);

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

    // Noise input based on position and time
    float n = noise(uv * 8.0 + iTime * 0.5);

    // Combine the flow, falloff, palette input, and noise for final color
    vec3 col = pal(palette_input) * m * dist_falloff * (1.0 + r * 0.7);

    // Apply noise to modulate the final color brightness/shift
    col = mix(col, vec3(n * 0.5 + 0.2), 0.5);

    // Apply the grid pattern overlay
    col = mix(col, vec3(grid_pattern), 0.2);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
