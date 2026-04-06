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

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    uv *= vec2(1.0 + 0.03 * sin(t + uv.x * 10.0), 1.0 + 0.03 * sin(t + uv.y * 15.0));
    return uv;
}

vec2 wave(vec2 uv) {
    // Combining the wave logic from both shaders
    float t = iTime * 0.5;

    // Distortion component from A
    uv *= 0.9 + 0.1 * cos(t * 0.5);

    // Wave component from B
    uv += vec2(cos(uv.x * 4.0 + iTime * 0.6) * 0.4, sin(uv.y * 3.0 + iTime * 0.7) * 0.4);
    uv += vec2(sin(uv.x * 2.5 + iTime * 0.3) * 0.3, cos(uv.y * 2.0 + iTime * 0.5) * 0.3);
    uv = vec2(sin(uv.x * 3.5 + iTime * 0.2), cos(uv.y * 2.5 + iTime * 0.4));
    return uv;
}

vec3 palette(float t) {
    // Color palette from A
    return vec3(0.1 + 0.4 * sin(t * 0.5 + iTime * 0.1), 0.4 + 0.4 * cos(t * 0.5 + iTime * 0.2), 0.6 + 0.1 * sin(t * 0.5 + iTime * 0.3));
}

vec3 colorFromWave(vec2 w)
{
    // Color mapping from B
    float r = 0.1 + 0.5 * sin(w.x * 20.0 + iTime * 0.5);
    float g = 0.4 + 0.4 * cos(w.y * 15.0 - iTime * 0.6);
    float b = 0.25 + 0.2 * sin(w.x * 7.0 + w.y * 4.0 + iTime * 1.0);
    return vec3(r, g, b);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // --- Coordinate Setup (Mixing Scaling and Distortion) ---

    // Initial scaling/time modulation
    float scaleA = 1.0 + 0.5*cos(iTime * 0.3);
    float scaleB = 1.0 + 0.5*fract(iTime * 0.4);
    uv *= vec2(1.0 + scaleA * 0.6, 1.0 + scaleA * 0.4);
    uv *= vec2(1.0 + scaleB * 0.5, 1.0 + scaleB * 0.5);

    // Apply distortion (using A's style)
    uv = distort(uv);

    // Apply rotation (using B's style)
    float angle = iTime * 0.7 + sin(uv.x * 5.0 + uv.y * 5.0) * 0.7;
    mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rot * uv;

    // Apply combined wave transformation (using the mixed definition)
    uv = wave(uv);

    // --- Color Generation ---

    // Base color based on wave coordinates
    vec3 col = colorFromWave(uv);

    // Flow and Pulse calculation (using B's style)
    float flow = sin(uv.x * 20.0 + iTime * 1.8) * 0.35; 
    float pulse = sin(uv.y * 12.0 + iTime * 1.0);

    // Layered modulation using flow and pulse
    float flow_mod = cos(uv.x * 15.0 + iTime * 0.1);
    float pulse_mod = sin(uv.y * 9.0 + iTime * 0.2);

    // Apply layered modulation using smoothstep
    col.r = smoothstep(0.2, 0.8, uv.x * 2.5 + flow * 6.0 + flow_mod * 0.7);
    col.g = smoothstep(0.3, 0.9, uv.y * 3.0 + pulse * 7.0 + pulse_mod * 0.4);
    col.b = 0.1 + 0.3 * sin(col.r * 1.2 + col.g * 1.5 + iTime * 0.5);

    // Apply flow and pulse as offsets
    col.r += flow * 0.7;
    col.g += pulse * 0.6;
    col.b += 0.15 * sin(uv.x * 11.0 + iTime * 0.3);

    // Final complex transformation (Mixing A's high-frequency effects)
    float final_shift = sin(uv.x * 7.0 + uv.y * 7.0 + iTime * 1.2);

    // Introduce color mixing based on the shift
    col.r = mix(col.r, 0.5 + cos(col.g * 15.0 - iTime * 0.4) * 0.5, final_shift * 0.25);
    col.g = mix(col.g, 0.6 + sin(col.r * 10.0 + uv.y * 4.0 - iTime * 0.3) * 0.4, final_shift * 0.3);
    col.b = 0.7 - 0.3 * cos(uv.x * 9.0 + uv.y * 5.0 + iTime * 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
