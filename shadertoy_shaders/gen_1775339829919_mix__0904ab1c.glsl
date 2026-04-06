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

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.5), cos(uv.y * 8.0 - iTime * 1.1));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.8 + iTime * 0.5);
    float g = 0.3 + 0.7 * sin(t * 1.3 + iTime * 0.3);
    float b = 0.1 + 0.6 * cos(t * 1.5 - iTime * 0.2);
    return vec3(r, g, b);
}

vec2 waveA(vec2 uv)
{
    return uv * 3.5 + vec2(
        sin(uv.x * 7.0 + iTime * 1.0) * 0.15,
        cos(uv.y * 5.5 - iTime * 0.9) * 0.1
    );
}

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.28,0.6)+t)); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // --- Wave and Flow Initialization (from Shader A) ---
    vec2 warped_uv = waveB(uv);

    // Apply rotational flow based on complex angle
    float angle = iTime * 0.3 + uv.x * 5.5;
    mat2 rotationMatrix = mat2(cos(angle), sin(angle), -sin(angle), cos(angle));
    warped_uv = rotationMatrix * warped_uv;

    // Apply secondary wave structure
    warped_uv = waveA(warped_uv);

    // Apply spatial flow
    float flow_x = iTime * 0.6 + uv.x * 2.5;
    float flow_y = iTime * 0.4 + uv.y * 3.5;

    // Use flow for positional shifting
    warped_uv.x += sin(flow_x * 1.2) * 0.1;
    warped_uv.y += cos(flow_y * 0.9) * 0.1;

    // --- Distance and Glow Mechanism (from Shader B) ---

    // Calculate polar coordinates and distance
    float a = atan(warped_uv.y, warped_uv.x);
    float r = length(warped_uv);

    float d = 1.0/(warped_uv.y + 1.15);
    float x_b = warped_uv.x * d * 4.0;
    float z_b = d + iTime * 2.0;

    // Glow calculation
    float lx = smoothstep(0.08, 0.0, abs(fract(x_b)-0.5));
    float lz = smoothstep(0.08, 0.0, abs(fract(z_b)-0.5));
    float glow = (lx + lz) * 0.6 / (1.0 + 0.15 * d * d);

    // --- Color Generation ---

    // Use a complex modulation for the base value
    float t = sin(warped_uv.x * 7.0 + iTime * 2.0) + cos(warped_uv.y * 6.0 + iTime * 0.8);

    // Combine the palette modulation (B) with the wave flow interaction (A) and glow
    vec3 col1 = palette(t * 1.8);
    vec3 final_col = pal(0.08 * z_b + 0.1 * x_b) * glow;

    // Introduce fractal noise based on high frequency interaction (A)
    float noise_factor = sin(warped_uv.x * 20.0 + iTime * 3.5) * cos(warped_uv.y * 12.0 - iTime * 1.0);

    // Blend colors
    final_col = mix(final_col, vec3(0.03, 0.18, 0.04), noise_factor * 0.8);

    // Introduce chromatic aberration based on UV position and flow (A)
    float aberration = abs(uv.x - 0.5) * 3.0;
    final_col.r += aberration * 0.15;
    final_col.b -= aberration * 0.15;

    // Intensity adjustment based on time variation (A)
    float intensity = 1.0 + 0.5 * sin(iTime * 0.5);
    final_col *= intensity;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
