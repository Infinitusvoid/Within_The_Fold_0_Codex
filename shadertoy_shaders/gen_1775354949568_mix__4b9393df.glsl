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

vec3 paletteA(float t)
{
    return vec3(
        0.05 + 0.3*sin(t * 0.8 + iTime * 0.1),
        0.3 + 0.4*cos(t * 1.1 + iTime * 0.2),
        0.6 + 0.2*sin(t * 0.9 + iTime * 0.3)
    );
}

vec3 paletteB(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Apply flow combined from A and B
    uv = flowA(uv);

    // Calculate polar coordinates based on the flowed UVs (from B structure)
    vec2 center_uv = vec2(0.5);
    vec2 offset = uv - center_uv;
    float r = length(offset);
    float a = atan(offset.y, offset.x);

    // Combine flow logic and depth influence
    float flow_speed = 1.5 + iTime * 1.0;

    // Influence z calculation based on radius (from B)
    float z = floor((1.0/(r+0.15) + iTime*2.0)*6.0)/6.0;

    // Phase calculation based on angular flow (from A/B combination)
    float phase = a * 15.0 + r * 4.0 + iTime * 0.7 + a * 5.0;
    float f = sin(phase * flow_speed);

    // Ripple effect (from A)
    float ripple = sin(r * 10.0 + iTime * 4.0) * 0.1 * (1.0 + abs(a));

    // Modulate color input based on radial position and time flow
    float palette_input = r * 1.8 + ripple * 0.5 + iTime * 0.5;

    // Contrast modulation (from A)
    float m = smoothstep(0.25, 0.15, abs(f));

    // Noise input (from B)
    float n = noise(uv * 8.0 + iTime * 0.5);

    // Density and Ring calculation (from A)
    float density = abs(sin(r * 5.0 + iTime * 3.0) * 2.0 + 1.0);
    float bands = smoothstep(0.5, 0.15, density);
    float ring = pow(sin(15.0*r + iTime * 6.0), 4.0);

    // Falloff (using A's more intense falloff)
    float dist_falloff = exp(-r * r * 1.5);

    // Final color calculation using palette B and modulation from A
    vec3 col = paletteB(palette_input) * m * dist_falloff * (1.0 + r * 0.7);

    // Apply complexity driven by rings and bands
    col *= 0.1 + 4.0*bands + 2.0*ring;

    // Introduce chromatic shift based on angle and time from B (using a slight modification)
    col += 0.3 * sin(a * 15.0 + iTime * 4.0);

    // Apply noise modulation
    col = mix(col, vec3(n * 0.5 + 0.2), 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
