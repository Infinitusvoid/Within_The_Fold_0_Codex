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
    vec2 p = uv * 5.0;
    p.x += iTime * 0.8;
    p.y += iTime * 1.2;

    // Generate layered noise patterns
    float n1 = noise(p * 2.5);
    float n2 = noise(p * 3.5 + iTime * 1.5);
    float n3 = noise(p * 4.0 + iTime * 3.0);

    // Calculate flow based on noise perturbation
    vec2 flow_base = vec2(cos(p.y * 2.0), sin(p.x * 2.0));

    // Use noise to modulate the flow direction and magnitude
    float flow_mod = n1 * 0.5 + n2 * 0.5;
    vec2 flow_dir = normalize(flow_base * (1.0 + flow_mod * 0.5) + iTime * 0.3);

    float flow_magnitude = 1.0 + sin(p.x * 3.0 + p.y * 1.5) * 0.7;

    // Introduce distance and depth effects
    vec2 center = vec2(0.5);
    vec2 offset = uv - center;
    float r = length(offset);
    float depth_effect = exp(-r * r * 10.0);

    // Combine flow and depth for modulation
    float flow_input = flow_magnitude * sin(p.x * 8.0 + iTime * 1.0);
    float depth_input = depth_effect * 2.0;

    // Palette modulation
    float palette_t = flow_input + depth_input * 0.5;
    vec3 col = pal(palette_t * 2.0);

    // Apply flow directionality and falloff
    vec3 final_color = col;
    final_color *= (1.0 + flow_input * 0.6);
    final_color *= depth_effect;

    // Blend with noise layers for texture
    float noise_blend = n3 * 0.6 + n1 * 0.4;
    final_color = mix(final_color, vec3(0.0, 0.3, 0.7) * noise_blend, 0.4);

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
