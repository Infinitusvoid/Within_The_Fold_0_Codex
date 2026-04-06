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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.1,0.4,0.7)+t)); }

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

    // Dynamic time-based shifting
    float time_shift = iTime * 0.5;

    // Flow based on UV and time, creating complex motion
    vec2 flow = uv * 20.0 + time_shift * 0.8;

    // Use flow for frequency and position
    vec2 p = flow * 1.5;

    // Layered frequency calculation modulated by time
    float freq_x = 15.0 + 10.0 * sin(flow.y * 1.2);
    float freq_y = 10.0 + 8.0 * cos(flow.x * 0.6);

    // Calculate base color using time-varying palette
    vec3 base_color = pal(p.x * 0.8) * 0.7 + pal(p.x * 0.8 + 0.5) * 0.3;

    // Introduce chaotic noise based on flow and time
    vec2 noise_coord = flow * 3.0 + iTime * 0.3;

    // Sample noise using offset coordinates
    float n1 = noise(noise_coord + vec2(0.5, 0.0));
    float n2 = noise(noise_coord + vec2(0.0, 0.5));

    // Use flow to modulate the noise scale and add complex cross-fade
    float flow_scale = 1.0 + sin(flow.x) * 1.8;

    // Mix base color with noise, using the difference between noise samples for intensity
    vec3 noise_mix = mix(vec3(0.0, 0.1, 0.5), vec3(1.0, 0.8, 0.1), n1);
    noise_mix = mix(noise_mix, vec3(0.9, 0.0, 0.1), n2);


    // Final color mixing based on distance and noise influence
    float dist_factor = 1.0 / (1.0 + length(uv) * 1.5);

    // Apply noise mix to the base color, modulated by flow scale
    vec3 final_color = mix(base_color, noise_mix, dist_factor * 0.9);

    // Introduce high contrast edge effect based on noise
    float edge_mask = smoothstep(0.5, 0.5 + n1 * 0.5, length(uv));
    final_color = mix(final_color, vec3(1.0), edge_mask * 0.3);


    fragColor = vec4(final_color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
