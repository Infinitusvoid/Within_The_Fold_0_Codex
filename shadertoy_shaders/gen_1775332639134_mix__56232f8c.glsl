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

vec2 waveC(vec2 uv)
{
    return vec2(sin(uv.x * 6.2 + iTime * 0.5), cos(uv.y * 7.0 - iTime * 0.45));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.y * 4.0 + iTime * 0.6), cos(uv.x * 8.0 + iTime * 0.3));
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.7 * sin(t * 1.5 - iTime * 0.3), 0.25 + 0.5 * cos(t * 0.8 + iTime * 0.15), 0.9 - 0.5 * sin(t * 0.7 + iTime * 0.05));
}

vec2 wave(vec2 uv) {
    float t = iTime * 0.8;
    return vec2(
        sin(uv.x * 4.5 + t * 1.6),
        cos(uv.y * 3.5 + t * 0.9)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.75 * sin(w.x * 12.0 + iTime * 0.3);
    float g = 0.5 + 0.4 * cos(w.y * 7.0 - iTime * 0.2);
    float b = 0.1 + 0.5 * sin(w.x * 6.0 + w.y * 4.0 + iTime * 0.5);
    return vec3(r, g, b);
}

vec2 smoothDistort(vec2 uv, float distortionNoiseMultiplier)
{
    float t = iTime * 0.6;
    float scale = 2.0;
    uv *= scale;
    uv.x += sin(uv.y * 7.0 + t * distortionNoiseMultiplier) * 0.08;
    uv.y += cos(uv.x * 5.0 + t) * 0.08;
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply initial distortion and time warp
    uv = smoothDistort(uv, 1.5 + sin(iTime * 0.5));
    uv = iTime * 0.5 + uv * 1.2;

    vec2 pos = uv;

    // UV space dynamic perturbation defining an arbitrary field angle
    float angle = iTime * 1.5 + sin(uv.x * 8.0 + iTime * 0.1) * cos(uv.y * 4.0) * 0.5;
    mat2 rotationMatrix = mat2(cos(angle*0.7), -sin(angle*0.7), sin(angle*0.7), cos(angle*0.7));
    pos = rotationMatrix * pos;

    // Apply base waves using the rotated position
    vec2 uv_rotated = pos;
    uv_rotated = waveC(uv_rotated);
    uv_rotated = waveD(uv_rotated);

    // New variable t based on combined wave states and time
    float t = sin(uv_rotated.x * 5.0 + iTime * 1.5) + cos(uv_rotated.y * 5.0 + iTime * 1.0) + sin(iTime * 0.5);
    vec3 base_color = palette(t);

    // Flow calculation based on wave components
    float flow_dot = sin(uv_rotated.y * 10.0 + iTime * 1.2) * cos(uv_rotated.x * 5.0);
    float flow_per = cos(uv_rotated.x * 12.0 + iTime * 0.9) * sin(uv_rotated.y * 6.0);

    // Calculate distortion based on flow interaction (from A)
    float distortion = flow_dot * flow_per * 1.2;

    // Use distortion to shift UVs slightly (from A)
    vec2 distorted_uv = uv_rotated;
    distorted_uv.x += distortion * 0.15;
    distorted_uv.y -= distortion * 0.1;

    // Calculate flow-based color shift (from A)
    vec3 flow_shift = vec3(flow_dot * 0.2, flow_per * 0.15, 1.0 - flow_dot * 0.3);

    // Mix base color and flow shift based on distortion magnitude
    vec3 final_color = mix(base_color, flow_shift, distortion * 2.0);

    // Introduce subtle ripple effect based on flow (from A)
    float ripple = flow_dot * 0.5;
    final_color.rgb += ripple * (1.0 - flow_per);

    // Secondary rotational influence (from B)
    float flow_sig = sin(pos.x * 7.5 + iTime * 2.0);
    float flare_sig = cos(pos.y * 9.0 - iTime * 1.8);

    // Layer flow calculations, strongly weighted by spatial variance and time (from B)
    float flow = sin(distorted_uv.x * 20.0 + iTime * 1.5) * flare_sig * 4.0;
    float pulse = cos(distorted_uv.y * 12.0 + iTime * 0.7);

    // Apply smoothstep modulation dynamically influenced by rotations and wave energy (from B)
    final_color.r = smoothstep(0.05, 0.85, distorted_uv.x * 3.0 + flow * 1.5);
    final_color.g = smoothstep(0.1, 0.7, distorted_uv.y * 4.0 + pulse * 2.0);

    // Sophisticated reflective/correlated adjustment using the inverse rotation structure (from B)
    final_color.b = 0.5 * sin(final_color.r * 1.5 + distorted_uv.x * 8.0 + flow_sig * 1.2);

    // Final coloration step incorporating diagonal complexity and inversion (from B)
    final_color.r = sin(final_color.g * 15.0 + distorted_uv.y * 6.5 + iTime * 1.1) * 0.5 + 0.35;
    final_color.g = cos(final_color.r * 9.0 - distorted_uv.x * 7.5 + iTime * 0.7) * 0.6 + 0.45;
    final_color.b = 0.7 + 0.3 * sin(iTime * 1.3 + distorted_uv.x * 2.5 + distorted_uv.y * 2.5);

    fragColor = vec4(final_color,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
