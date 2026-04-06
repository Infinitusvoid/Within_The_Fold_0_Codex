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
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv) {
    float t = iTime * 0.5;
    float scale = 1.8;
    uv *= scale;
    uv.x += sin(uv.y * 6.0 + t * 2.0) * 0.15;
    uv.y += cos(uv.x * 5.0 + t) * 0.1;
    return uv;
}

mat2 rotate(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

vec2 flow(vec2 uv)
{
    float speed = 0.5;
    float frequency = 8.0;
    float time_offset = iTime * speed;

    float val1 = sin(uv.x * frequency + time_offset);
    float val2 = cos(uv.y * frequency * 1.5 - time_offset * 0.5);

    float warp_x = val1 * 0.6 + val2 * 0.4;
    float warp_y = cos(uv.x * frequency + val1 * 1.5) * 0.2 + val2 * 1.2;

    return vec2(warp_x, uv.y + warp_y);
}

vec3 modulate(float input, float time)
{
    vec3 c1 = vec3(0.1 * sin(input * 5.0 + time * 1.5), 0.5 + 0.5 * cos(input * 3.0 + time * 1.0), 0.9);
    vec3 c2 = vec3(0.9, 0.1 * cos(input * 7.0 + time * 2.0), 0.55);

    vec3 final_color = mix(c1, c2, fract(input * 3.7));
    return final_color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Combine geometry operations (Shader A and B style coordinate flow setup)
    uv = distort(uv);

    // Calculate dynamic rotation from previous steps
    float angle = iTime * 0.7 + sin(uv.x * 5.0 + uv.y * 3.5) * 0.4;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    // Apply positional flow transformation based on spatial coordinates
    uv = flow(uv);

    // Calculate wave structure overlay (Shader A based aesthetic)
    vec2 w = wave(uv);
    vec3 col = colorFromWave(w);

    // Shape the color using flow metrics (Shader B logic based coloring base)
    float f_factor = uv.x * 2.0 + uv.y * 1.5 + iTime * 0.8;
    float anim_cycle = mod(sin(f_factor) * 5.0 + iTime * 0.5, 10.0);

    // Apply modulating flow color
    col = modulate(anim_cycle, iTime / 3.0);

    // Post-process layering and manipulation
    float flow = sin(uv.x * 20.0 + iTime * 1.2) * 0.2;
    float pulse = sin(uv.y * 15.0 + iTime * 0.9);


    // Smoothstep based coloring based on movement and wave input (Shader A derived layer modification)
    float intensity = 0.5 + 0.5 * sin(uv.x * 8.0 + iTime * 0.3);

    col.r = smoothstep(0.3, 0.6, uv.x * 2.5 + flow * 6.0);
    col.g = smoothstep(0.2, 0.5, uv.y * 3.5 + pulse * 5.0);
    col.b = 0.1 + 0.4 * sin(col.r * 1.8 + col.g * 1.8 + iTime * 0.5);


    // Final aesthetic refinement mix (Reintroducing derived math flow structure from A implicitly merged with B focusing focus)
    col.r += flow * 0.8;
    col.g += pulse * 0.7;
    col.b += 0.25 * sin(uv.x * 10.0 + iTime * 0.4);

    col.r = cos(col.g * 10.0 + iTime * 0.5) * 0.5 + 0.5;
    col.g = sin(col.r * 8.0 - uv.y * 6.0 + iTime * 0.4) * 0.5 + 0.5;
    col.b = 0.5 + 0.5 * sin(uv.x * 7.0 + uv.y * 7.0 + iTime * 0.7);


    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
