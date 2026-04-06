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

vec2 waveB(vec2 uv)
{
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 3.0 + iTime * 0.6) * 0.08,
        cos(uv.y * 2.5 - iTime * 0.4) * 0.12
    );
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 5.0 + iTime * 1.5);
    float g = cos(uv.y * 6.0 + iTime * 2.0);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Initial scaling and centering
    uv = uv * vec2(3.0, 2.0) - vec2(0.5, 0.5);

    // --- Wave Distortion (From A) ---
    uv = waveB(uv);
    uv = waveA(uv);

    // Apply ripple distortion
    vec2 d = ripple(uv);
    uv = uv + d * 0.7;

    // --- Geometric Rotation (From A) ---
    float flow_t = iTime * 0.6;

    mat2 rotationMatrix = mat2(cos(uv.y * 2.0 + flow_t), -sin(uv.x * 2.5 + flow_t), sin(uv.x * 2.5 + flow_t), cos(uv.y * 2.0 + flow_t));
    uv = rotationMatrix * uv;

    // Apply wave again after rotation
    uv = waveB(uv);

    // --- Complex Flow and Modulation (From A ? B) ---

    // Distortion based on secondary flow calculation
    vec2 distorted_uv = uv;
    float scale = 2.0;
    distorted_uv *= scale;
    distorted_uv.x += sin(distorted_uv.y * 8.0 + flow_t * 2.0) * 0.3;
    distorted_uv.y += cos(distorted_uv.x * 4.0 + flow_t * 1.5) * 0.25;

    uv = distorted_uv;

    // Retrieve dynamic system feedback from WaveB (A)
    vec2 w = waveB(uv); 
    float flow_mag = abs(sin(w.x * 12.0 + iTime * 3.5));
    float pulse_mag = abs(cos(w.y * 8.0 - iTime * 2.8));

    // --- Polar Flow and Falloff (From B) ---

    // Calculate polar coordinates based on the distorted UV
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Dynamic flow based on time and polar coordinates (B)
    float flow_speed = 3.0 + iTime * 2.0;
    float phase = a * 8.0 + r * 4.0 + iTime * 1.0;

    // Introduce a secondary distortion based on frame
    float frame_distortion = sin(iFrame * 0.1) * 0.5;

    float f = sin(phase);

    // Use exponential falloff for focus (B)
    float dist_falloff = exp(-r * r * 0.6);

    // Combine flow and distortion influence
    float m = smoothstep(0.2, 0.05, abs(f + frame_distortion));

    // --- Core Color Generation (Mixed logic) ---

    // Use the palette function (A structure)
    float t_base = flow_mag * 0.5 + iTime * 0.5;
    float base_val = uv.x * 6.0 + uv.y * 3.0;

    // Determine the three inputs for the palette function dynamically
    float t1 = t_base;
    float t2 = t_base + 0.5;
    float t3 = t_base + 1.0;

    // Calculate R, G, B components using the palette
    vec3 color = pal(t1) + pal(t2) * 0.5 + pal(t3) * 0.5;

    // Apply flow/pulse modulation (A)
    float r_mod = smoothstep(0.0, 0.8, base_val * 1.5 + flow_mag * 3.0);
    float g_mod = smoothstep(0.2, 0.9, uv.y * 2.5 + pulse_mag * 4.0);

    // Apply flow contrast derived from WaveB (A)
    vec3 final_color = vec3(
        r_mod * (1.0 + flow_mag * 0.5),
        g_mod * (1.0 + flow_mag * 0.5),
        color.b * (1.0 + flow_mag * 0.2)
    );

    // Apply polar falloff and flow influence to the final color
    vec3 final_output = final_color * m * dist_falloff;

    fragColor = vec4(final_output, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
