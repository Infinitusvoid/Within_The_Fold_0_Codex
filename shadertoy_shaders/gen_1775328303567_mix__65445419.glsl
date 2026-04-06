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

vec2 noise(vec2 uv)
{
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return vec2(sin(6.28318 * (i.x + u.x)), cos(6.28318 * (i.y + u.y)));
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    float scale = 2.5;
    uv *= scale;
    uv.x += sin(uv.y * 8.0 + t * 2.0) * 0.1;
    uv.y += cos(uv.x * 6.0 + t) * 0.1;
    return uv;
}

vec2 wave(vec2 uv)
{
    float t = iTime * 0.8;
    // Based partially on A's definition but T modulates the waves heavily
    return vec2(sin(uv.x * 7.0 + t * 1.5), cos(uv.y * 5.0 - t * 1.0));
}

vec3 colorFromWave(vec2 w)
{
    // Merging the specific temporal shifts and pattern derived from both A and B structures
    float i = iTime;
    float r = 0.5 + 0.5 * sin(w.x * 12.0 + i * 0.5); // Weight shifted and amplified
    float g = 0.5 + 0.5 * cos(w.y * 10.0 - i * 0.4); // Y motion emphasis
    float b = 0.3 + 0.7 * sin(w.x * 3.0 + w.y * 2.0 + i * 0.6); // Base complex tone
    return vec3(r, g, b);
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Step 1: Apply spatial distortion based on general T variation (A/B common setup)
    uv = distort(uv);

    // Step 2: Dynamic Rotation (Derived from both, but combined movement patterns)
    float angle = iTime * 0.5 + sin(uv.x * 6.0 + uv.y * 4.0) * 0.5;
    mat2 rot = rotate(angle);
    uv = rot * uv;

    // Step 3: Base Wave Calculation (A function preferred, subtle modulation)
    vec2 w = wave(uv);

    // Base Material
    vec3 col = colorFromWave(w);

    // Flow calculation modulated by time and position
    float flow = sin(uv.x * 30.0 + iTime * 1.5) * 0.25;
    float pulse = sin(uv.y * 20.0 + iTime * 1.0) * 0.5;

    // Layered Density and Saturation based on geometry (B smoothstep focus)
    float depth_saturation = 1.0 + 0.5 * sin(uv.x * 10.0 + iTime * 0.3);

    // Apply flow and pulse blending via smoothstep channels
    // Make flowing part influence highlight distribution
    float flow_mask = smoothstep(sin(uv.x * 10.0), sin(uv.x * 7.0 + flow * 5.0), uv.x);
    float pulse_base = smoothstep(0.1, 0.7, uv.y * 4.0 + pulse * 6.0);

    // Color Modulation blending
    col.r = col.r * depth_saturation;
    col.g = col.g * depth_saturation;

    // Ingoing flow energy
    col.r += flow * 0.5;
    col.g += flow * 0.3;

    // Dynamic base element update
    col.b = 0.5 + 0.5 * sin(uv.x * 7.0 + uv.y * 7.0 + iTime * 0.8);

    // High dynamic contrast and final accent layer
    col.r = pow(col.r, 1.5) * 1.1;
    col.g = 0.5 + sin(col.r * 5.0 + uv.y * 5.0 + iTime * 0.4) * 0.2;

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
