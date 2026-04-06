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
        sin(uv.x * 5.0 + t * 1.5),
        cos(uv.y * 4.0 + t * 0.8)
    );
}

vec3 colorFromWave(vec2 w) {
    float r = 0.5 + 0.5 * sin(w.x * 10.0 + iTime * 0.5);
    float g = 0.5 + 0.5 * cos(w.y * 8.0 - iTime * 0.4);
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + iTime * 0.6);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.6;
    float scale = 1.5;
    uv *= scale;
    uv.x += sin(uv.y * 5.0 + t) * 0.05;
    uv.y += cos(uv.x * 5.0 + t) * 0.05;
    return uv;
}

float palette(float t) {
    t = fract(t * 3.14159);
    return 0.5 + 0.5 * sin(t * 20.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;

    // Apply initial warping and distortion from B
    uv = distort(uv);

    // Introduce complexity and base time flow from A
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 1.5) * 0.3;

    // Calculate rotation fields, mixing elements based on movement

    // Rotate first by combining some planar movement information from combined flows
    float angleA = iTime * 0.8 + uv.x * uv.y * 4.0;
    mat2 rot = mat2(cos(angleA), -sin(angleA), sin(angleA), cos(angleA));
    uv = rot * uv;

    // Introduce motion flow derivatives
    float flow_flow = sin(uv.x * 3.0 + iTime * 0.5) * 0.1;

    // Wave generation structure inherited from A via wave definition
    vec2 w = wave(uv);

    // Use B's complex distance patterning and coloring
    vec3 color = colorFromWave(w);

    // Blend the spatial and color features
    color.r = iTime * 12.0 + uv.x * flow_flow * 5.0 + color.r;
    color.g = uv.y * color.r * 0.15 + cos(uv.y * 4.0 + flow_flow + iTime * 0.8);
    color.b = 0.1 + 0.3 * sin(color.x + color.y + iTime);

    // Apply final temporal and ambient shifts, utilizing spectral palette idea
    float brightness_contrast = abs(w.x) + uv.y;
    float final_shift = sin(iTime * 5.0 * brightness_contrast + uv.x * 6.5);

    color.r = mix(color.r, final_shift * 10.0, uv.y * final_shift);
    color.g = mix(color.g, 0.5, final_shift * uv.x * 1.5);
    color.b = mix(color.b, 1.0 / (1.0 + dot(w, w)), final_shift);

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
