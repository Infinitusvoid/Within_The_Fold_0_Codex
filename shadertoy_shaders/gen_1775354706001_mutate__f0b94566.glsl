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
    vec2 uv = fragCoord / iResolution.xy;

    // Calculate base time and spatial coordinates
    vec2 p = uv * 3.0;
    p.x += iTime * 0.5;
    p.y += iTime * 0.3;

    // Generate multi-layered noise for complex flow field
    float n1 = noise(p * 1.5);
    float n2 = noise(p * 2.0 + iTime * 2.0);

    // Calculate flow vectors based on gradients and time
    vec2 flow_dir = normalize(vec2(cos(p.y), sin(p.x)) * 1.0 + iTime * 0.5);
    float flow_magnitude = 1.0 + sin(p.x * 2.0 + p.y * 3.0) * 0.5;

    // Introduce ripple based on distance from center and time
    vec2 center = vec2(0.5);
    vec2 offset = uv - center;
    float r = length(offset);
    float ripple = sin(r * 15.0 + iTime * 8.0) * 0.1;

    // Combine flow and ripple into a complex modulation input
    float flow_input = flow_magnitude * sin(p.x * 10.0 + iTime);
    float ripple_input = ripple * 4.0;

    // Palette modulation using combined values
    float palette_t = flow_input + ripple_input;
    vec3 col = pal(palette_t * 1.5);

    // Final color calculation using noise as a texture layer
    float noise_mod = n1 * 0.5 + n2 * 0.5;

    // Apply flow directionality and falloff
    vec3 final_color = col;
    final_color *= (1.0 + flow_input * 0.5);
    final_color *= exp(-r * r * 1.5);

    // Blend with noise pattern
    final_color = mix(final_color, vec3(0.1, 0.5, 0.9) * noise_mod, 0.3);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
