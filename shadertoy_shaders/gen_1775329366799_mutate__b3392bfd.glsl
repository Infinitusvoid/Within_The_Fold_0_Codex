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

vec2 distort(vec2 uv)
{
    float t = iTime * 0.8;
    float roughness = 10.0 + sin(uv.x * 18.0 + iTime * 3.0) * 5.0;
    uv.x += sin(uv.y * 10.0 + t * 0.5) * 0.1 * roughness;
    uv.y += cos(uv.x * roughness / 15.0 + t * 0.8) * 0.1 * roughness;
    return uv;
}

float flow(vec2 uv, float t)
{
    float phase1 = iTime + uv.x * 1.5;
    float phase2 = uv.y * 4.0 + t;
    float mix = sin(phase1 * 0.5 + uv.y * 2.0) * 0.1;
    return mix * 2.0;
}

vec2 wave(vec2 uv)
{
    float a = iTime * 0.5;
    float b = iTime * 0.3;
    return vec2(sin(uv.x * 5.0 + a), cos(uv.y * 3.5 + b));
}

vec3 complexColor(float r, float t)
{
    float color_shift = sin(r * 12.0 + t * 2.71828); // Golden Ratio-inspired movement
    float t_effect = cos(t * 3.1) * 1.5;

    float r1 = r * (1.0 + color_shift);
    float g1 = sin(t_effect * 4.0) * 0.5;
    float b1 = t_effect * 0.5 + g1;

    return vec3(r1 * 0.8, g1 * 0.8, b1);
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = distort(uv);

    float t = iTime * 1.5;

    vec2 w = wave(uv * 3.0);

    // Define rotation influence based on complex UV manipulation
    float v_rot = flow(uv, t);

    // Angle influences overall flow sweep
    float angle = (t + uv.y * 5.0 + v_rot) * 5.0;
    mat2 rot = rotate(angle * 0.5);
    vec2 rotated_uv = rot * uv;

    float energy = uv.x * uv.y * 4.0;

    vec3 base_color = complexColor(energy + rotated_uv.x, t);

    // Apply distortion based glow derived from coordinate positions and time
    float glow = sin(rotated_uv.x * 5.0 + iTime) * v_rot * 1.5;
    vec3 final_col = base_color;

    final_col.r += glow * 1.5;
    final_col.g *= (1.0 - glow * 0.6);
    final_col.b = sin(t * 2.0) * final_col.b * flow(uv, t/2.0);

    // Enhance the perceived depth/structure with exponential noise scale
    float distortion_val = exp(-energy * 0.5 - t * 0.7);

    fragColor = vec4(final_col * 2.2, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
