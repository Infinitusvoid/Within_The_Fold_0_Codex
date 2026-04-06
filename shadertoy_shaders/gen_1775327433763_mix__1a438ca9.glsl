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

vec2 transform_uv(vec2 uv)
{
    float t = iTime * 0.6 + uv.x * 1.5;
    float scale_x = 1.0 + 0.1 * sin(t * 6.2 + uv.x * 30.0);
    float scale_y = 1.0 + 0.12 * cos(t * 5.8 + uv.y * 25.0);
    uv.x *= scale_x;
    uv.y *= scale_y;
    uv.x += iTime * 0.15;
    uv.y += iTime * 0.1;
    return uv;
}

vec2 wave(vec2 uv)
{
    float t = iTime * 0.5 + uv.x * 0.5;
    float t2 = iTime * 0.5 + uv.y * 1.0;
    float s = 10.0 + t;

    float r = sin(uv.x * s + t * 0.7);
    float g = cos(uv.y * s - t2 * 0.8);
    float b = sin(uv.x * 3.0 + uv.y * 2.0 + t * 1.0);

    return vec2(r, g);
}

vec3 colorFromWave(vec2 w)
{
    // Integration of simpler palette fluctuation A, driven by wave results
    float pa = 0.5 + 0.5 * sin(w.x * 4.0 + iTime * 1.5);
    float pb = 0.5 + 0.5 * cos(w.y * 5.5 - iTime * 0.9);
    float pc = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.5 + iTime * 0.4);

    return vec3(pa, pb, pc);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Initial distortion/flow
    uv = transform_uv(uv);

    // 2. Rotation focusing transform layer
    float flow_time = iTime * 1.5 + uv.x * 10.0;
    float motion_y = iTime * 0.9 + uv.y * 15.0;

    float rotation_angle = sin(flow_time + uv.x * 25.0) * 0.8;
    mat2 rot = mat2(cos(rotation_angle), -sin(rotation_angle), sin(rotation_angle), cos(rotation_angle));

    uv = rot * uv;

    // 3. Calculate fundamental waves derived by Shader B style
    vec2 w = wave(uv);

    // 4. Introduce interaction and ripple derived structure
    float freq_x = uv.x * 8.0 + flow_time;
    float freq_y = uv.y * 7.0 + motion_y;

    float ripple = sin(freq_x * 18.0) * sin(freq_y * 22.0) * 0.15;

    // 5. Primary color generation
    vec3 color = colorFromWave(w);

    // Smoothstep based intensity modulation inherited from combining components
    float intensity = smoothstep(0.2, 0.7, uv.x * 2.0 + ripple * 1.8 + sin(flow_time * 5.0));
    color.r = color.r * intensity * 2.0; 

    // Secondary color mixing and fine detail (using highly specific multipliers from setup)
    color.g = cos(color.r * 10.0 + flow_time * 3.5 + uv.y * 6.0);
    color.b = 0.5 + 0.5 * sin(float(freq_x * 4.5) + float(uv.x) * 5.0 * (w.x + w.y)) + color.r * 0.5;

    // Final feedback layer using soft looping for glow/swirl
    color.r = sin(color.g * 9.0 + iTime * 0.6) * 0.5 + 0.5;
    color.g = cos(color.r * 12.0 - uv.y * 8.5 + iTime * 0.5) * 0.5 + 0.5;
    color.b = max(0.3, color.b + sin(uv.x * 6.0 + uv.y * 10.0) * float(iTime * 1.8));

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
