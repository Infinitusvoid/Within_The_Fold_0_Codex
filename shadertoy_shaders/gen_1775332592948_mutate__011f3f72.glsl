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
    // Enhanced wave pattern
    float x_coord = uv.x * 10.0;
    float y_coord = uv.y * 10.0;
    return vec2(sin(x_coord * 6.0 + t * 3.0), cos(y_coord * 5.0 - t * 2.5));
}

vec3 modulate_color(vec2 uv, vec2 waveCoord, float timeVal) {
    float base_f = uv.x * 3.0 + uv.y * 3.0;
    float density = 0.5 + 0.5 * sin(base_f * 8.0 + timeVal * 1.5);

    // Introduce a secondary phase shift based on wave coordinates
    float phase_shift = waveCoord.x * 1.5 + waveCoord.y * 0.5;

    float R = density + sin(base_f * 12.0 + phase_shift * 5.0 + timeVal) * 0.5;
    float G = density + cos(base_f * 9.0 + phase_shift * 4.0 - timeVal) * 0.5;
    float B = 0.4 + sin(R * 7.0 + G * 3.0 + timeVal * 1.2);

    // Apply light depth based on flow related terms
    float flow = sin(waveCoord.x * 15.0 + 3.0 * timeVal) * (1.0 - distance(uv, vec2(0.5, 0.5)) * 2.0);
    B = mix(B, 1.0 - flow, flow * 0.5);

    return vec3(R, G, B);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply flow distortion influenced by time and overall coordinate shift
    vec2 flow_uv = smooth_scale2(uv, 2.5, iTime * 1.8);

    // Calculate background rotation dynamically
    float rotation = iTime * 2.0 + sin(flow_uv.x * 5.0) * 1.5;

    // Transform UVs based on rotation
    mat2 rot = mat2(cos(rotation), -sin(rotation), sin(rotation), cos(rotation));
    vec2 rotated_uv = rot * uv;

    // Introduce complex internal distortion through frequency
    rotate(rotated_uv, rotation);
    float internal_shift = sin(flow_uv.y * 8.0 + iTime * 0.8) * 0.2;
    rotated_uv.x += internal_shift * 0.7;
    rotated_uv.y += cos(rotated_uv.x * 2.0) * internal_shift * 0.9;

    // Calculate wave structure
    vec2 w = wave(rotated_uv);

    // Get modulated color result
    vec3 col = modulate_color(rotated_uv, w, iTime * 0.6);

    // Final post-processing glow and intensity adjustment
    float final_intensity = smoothstep(0.1, 0.9, log(uv.x*5.0 + uv.y*6.0 + iTime * 4.0) / 2.5);

    col *= final_intensity * 2.0;

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
