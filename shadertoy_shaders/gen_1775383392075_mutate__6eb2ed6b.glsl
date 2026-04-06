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

vec2 flowA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 7.0 + iTime * 1.5) * 0.1,
        cos(uv.y * 5.5 + iTime * 1.0) * 0.15
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 9.0 + iTime * 0.7) * 0.2,
        cos(uv.y * 6.0 + iTime * 0.9) * 0.25
    );
}

vec3 palette(float t)
{
    return vec3(
        0.1 + 0.5*sin(t * 10.0 + iTime * 0.5),
        0.5 + 0.4*cos(t * 12.0 + iTime * 0.3),
        0.8 + 0.2*sin(t * 8.0 + iTime * 0.7)
    );
}

vec3 pal(float t)
{
    return 0.1 + 0.9 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
}

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

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Apply initial flow distortion from B
    uv = flowB(uv);

    // Calculate polar coordinates
    vec2 center_uv = vec2(0.5);
    vec2 offset = uv - center_uv;
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // Depth factor (from A, modified by B's concept)
    float z = 1.0 / (r * 1.8 + 0.3);

    // Flow and phase modulation based on A's geometric setup
    float angle_flow = sin(a * 18.0 + iTime * 4.0);
    float radial_shift = z * 1.5;

    float phase_a = 18.0*a + iTime * 2.5 + angle_flow;
    float phase_r = 25.0*r + radial_shift + iTime * 2.0;

    float f1 = sin(phase_a * 0.7);
    float f2 = cos(phase_r * 1.3);

    // Create complex density based on interaction
    float density = abs(f1 * f2 * 3.0);
    float bands = smoothstep(0.6, 0.1, density);

    // Create dynamic, oscillating rings from A
    float ring = pow(sin(20.0*r + iTime * 8.0), 3.5);

    // Ripple effect from B
    float ripple = sin(r * 10.0 + a * 6.0 + iTime * 4.0) * 0.2;

    // Use exponential falloff tied to radial position (from B)
    float dist_falloff = exp(-1.5*r * r * 0.9);

    // Introduce angular banding based on flow (from B)
    float band = sin(a * 12.0 + iTime * 3.0) * 0.15;

    // Modulation factor based on the ripple and angular complexity
    float modulation = ripple * 2.0 + band;

    // Base palette value driven by radius, flow, and depth interaction
    float palette_t = 0.01*iTime + f1*0.8 + radial_shift*0.5;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.05 + 5.0*bands + 3.0*ring;

    // Apply noise using B's noise function
    float n = noise(uv * 12.0 + iTime * 0.5);

    // Introduce the ripple/band modulation into the color intensity
    col *= (1.0 + modulation * 0.6);

    // Contrast applied by flow state (from B)
    float m = smoothstep(0.1, 0.05, abs(f2));

    // Final color calculation combining falloff and noise modulation
    col *= dist_falloff;
    col += n * 0.5;

    // Apply chromatic shift based on angle and time from A
    col += 0.4 * sin(a * 20.0 + iTime * 5.0);

    // Final slight refinement using flowA
    uv = flowA(uv);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
