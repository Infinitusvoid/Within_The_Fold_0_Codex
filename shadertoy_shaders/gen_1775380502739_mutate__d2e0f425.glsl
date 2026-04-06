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
    float t = iTime * 0.5;
    return vec2(
        sin(uv.x * 4.5 + t * 3.0),
        cos(uv.y * 7.0 + t * 1.5)
    );
}

float palette(float t) {
    t = fract(t * 1.3);
    return 0.5 + 0.5 * sin(t * 25.0 + 4.0);
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.1,0.4,0.7)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // --- Shader A: Polar Coordinates and Radial Focus ---
    vec2 center = vec2(0.5);
    vec2 p = uv - center;
    float r = length(p);
    float theta = atan(p.y, p.x);

    // Radial influence, defining the inner/outer focus
    float radial_influence = 1.0 - smoothstep(0.0, 0.4, r);

    // Time modulation based on position and rotation
    float t = iTime * 2.0 + r * 4.0 + theta * 5.0;

    // High frequency oscillation
    float r_mod = sin(t * 8.0 + theta * 15.0) * 0.5 + 0.5;
    float g_mod = cos(t * 3.0 + r * 6.0) * 0.5 + 0.5;
    float b_mod = sin(t * 7.0 + theta * 10.0) * 0.5 + 0.5;

    // Base palette input value
    float p_input = radial_influence * 8.0 + t;

    // --- Shader B: Rotation, Waves, and Flow ---

    // Apply rotation based on time and UV interaction
    float angleA = iTime * 1.2 + uv.x * 4.0;
    mat2 rotA = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    vec2 rotatedUV = rotA * uv;

    float angleB = iTime * 0.8 + uv.y * 3.5;
    mat2 rotB = mat2(cos(angleB), -sin(angleB), sin(angleB), cos(angleB));
    rotatedUV = rotB * rotatedUV;

    // Wave generation
    vec2 w = wave(rotatedUV * 1.8);

    // Smooth transition based on wave interaction (Flow)
    float flow = w.x * 0.6 + w.y * 0.4;

    // Modified flow calculation, influenced by radial distance
    float radial_flow = flow * (1.0 - r * 0.5); 

    float intensity = smoothstep(0.25, 0.8, radial_flow);

    // --- Combining Color Logic ---

    // Calculate base color using Shader A's complex palette
    vec3 color = pal(p_input) * r_mod + pal(p_input + 0.2) * g_mod + pal(p_input + 0.4) * b_mod;

    // Apply dynamic modulation from Shader B flow
    vec3 final_color = mix(color, vec3(palette(iTime * 1.2 + rotatedUV.y * 0.5) * 0.5 + 0.05), intensity * 0.8);

    // Apply ambient lighting based on radial falloff (from A)
    float ambient = 0.2 + radial_influence * 1.5;
    final_color *= ambient * (1.0 + sin(t * 3.0));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
