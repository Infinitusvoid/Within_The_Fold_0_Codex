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

vec2 smooth_scale2(vec2 uv, float scale_var, float time_var) {
    vec2 projected_uv = uv * scale_var;
    projected_uv.x += sin(time_var * 3.0 + projected_uv.y * 6.5) * 0.25;
    projected_uv.y += cos(projected_uv.x * 5.5 + time_var * 3.5) * 0.18;
    return projected_uv;
}

vec2 rotate(vec2 uv, float angle) {
    return vec2(
        uv.x * cos(angle) - uv.y * sin(angle),
        uv.x * sin(angle) + uv.y * cos(angle)
    );
}

vec2 wave(vec2 uv) {
    float t = iTime * 1.1;
    // Shifted wave pattern based on complex coordinates
    float x_coord = uv.x * 15.0;
    float y_coord = uv.y * 15.0;
    // Multi-frequency, phase-shifted wave
    return vec2(sin(x_coord * 7.0 + t * 5.0), cos(y_coord * 8.0 - t * 3.0));
}

vec3 modulate_color(vec2 uv, vec2 waveCoord, float timeVal) {
    float base_f = uv.x * 4.0 + uv.y * 4.0;
    // Density fluctuation based on phase correlation
    float density = 0.5 + 0.5 * sin(base_f * 8.0 + timeVal * 2.5);

    // Phase shift driven by wave coordinates
    float phase_shift = waveCoord.x * 2.0 + waveCoord.y * 1.5;

    // R channel derivation
    float R = density + sin(base_f * 15.0 + phase_shift * 7.0 + timeVal * 2.0) * 0.5;
    // G channel derivation
    float G = density + cos(base_f * 11.0 + phase_shift * 5.0 - timeVal * 1.5) * 0.4;
    // B channel derivation, reacting to R and G
    float B = 0.2 + R * 0.6 + G * 0.4;

    // Introduce flow-based color shift using distance and time
    float flow = sin(waveCoord.x * 20.0 + timeVal * 1.5) * (1.0 - dot(uv, vec2(0.5, 0.5)) * 3.0);

    // Blend R and G based on flow
    R = mix(R, 1.0 - flow * 0.5, flow * 0.6);
    G = mix(G, 1.0 - flow * 0.5, flow * 0.6);

    return vec3(R, G, B);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply strong dynamic flow distortion
    vec2 flow_uv = smooth_scale2(uv, 4.0, iTime * 3.0);

    // Calculate rotation driven by internal movement
    float rotation = iTime * 2.8 + sin(flow_uv.x * 12.0) * 1.5;

    // Transform UVs based on rotation
    mat2 rot = mat2(cos(rotation), -sin(rotation), sin(rotation), cos(rotation));
    vec2 rotated_uv = rot * uv;

    // Introduce rotation and subtle movement
    rotate(rotated_uv, rotation);
    float internal_shift = sin(flow_uv.y * 15.0 + iTime * 1.2) * 0.2;
    rotated_uv.x += internal_shift * 1.3;
    rotated_uv.y += cos(rotated_uv.x * 4.0) * internal_shift * 1.5;

    // Calculate wave structure
    vec2 w = wave(rotated_uv);

    // Get modulated color result
    vec3 col = modulate_color(rotated_uv, w, iTime * 1.2);

    // Final intensity calculation based on logarithmic mapping and frame offset
    float intensity_base = log(uv.x*7.0 + uv.y*8.0 + iTime * 4.0) / 2.4;
    float final_intensity = smoothstep(0.03, 1.0, intensity_base * 1.2 + sin(iFrame * 0.4) * 0.15);

    col *= final_intensity * 2.0;

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
