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
        sin(uv.x * 6.0 + iTime * 1.2) * 0.15,
        cos(uv.y * 7.0 + iTime * 0.8) * 0.1
    );
}

vec2 flowB(vec2 uv)
{
    return vec2(
        sin(uv.x * 8.0 + iTime * 0.4) * 0.25,
        cos(uv.y * 5.0 + iTime * 0.6) * 0.2
    );
}

vec3 palette(float t)
{
    return vec3(
        0.05 + 0.3*sin(t * 0.8 + iTime * 0.1),
        0.3 + 0.4*cos(t * 1.1 + iTime * 0.2),
        0.6 + 0.2*sin(t * 0.9 + iTime * 0.3)
    );
}

vec3 pal(float t)
{
    return 0.5 + 0.5 * sin(6.28318 * t * 3.0 + 3.14159 * vec3(0.1, 0.5, 0.9));
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
    float z = 1.0 / (r * 1.5 + 0.5);

    // Flow and phase modulation based on A's geometric setup
    float angle_flow = sin(a * 20.0 + iTime * 3.0);
    float radial_shift = z * 1.2;

    float phase_a = 15.0*a + iTime * 1.2 + angle_flow;
    float phase_r = 20.0*r + radial_shift + iTime * 1.5;

    float f1 = sin(phase_a * 0.8);
    float f2 = cos(phase_r * 1.1);

    // Create complex density based on interaction
    float density = abs(f1 * f2 * 2.5);
    float bands = smoothstep(0.5, 0.15, density);

    // Create dynamic, oscillating rings from A
    float ring = pow(sin(15.0*r + iTime * 6.0), 4.0);

    // Ripple effect from B
    float ripple = sin(r * 8.0 + a * 5.0 + iTime * 3.0) * 0.15;

    // Use exponential falloff tied to radial position (from B)
    float dist_falloff = exp(-1.2*r * r * 0.7);

    // Introduce angular banding based on flow (from B)
    float band = sin(a * 10.0 + iTime * 2.0) * 0.1;

    // Modulation factor based on the ripple and angular complexity
    float modulation = ripple * 1.5 + band;

    // Base palette value driven by radius, flow, and depth interaction
    float palette_t = 0.05*iTime + f1*0.7 + radial_shift*0.4;

    vec3 col = pal(palette_t);

    // Apply complexity driven by rings and bands
    col *= 0.1 + 4.0*bands + 2.0*ring;

    // Apply noise using B's noise function
    float n = noise(uv * 10.0 + iTime * 0.3);

    // Introduce the ripple/band modulation into the color intensity
    col *= (1.0 + modulation * 0.5);

    // Contrast applied by flow state (from B)
    float m = smoothstep(0.2, 0.1, abs(f2));

    // Final color calculation combining falloff and noise modulation
    col *= dist_falloff;
    col += n * 0.3;

    // Apply chromatic shift based on angle and time from A
    col += 0.3 * sin(a * 15.0 + iTime * 4.0);

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
