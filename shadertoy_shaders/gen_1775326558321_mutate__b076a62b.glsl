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

vec2 wave(vec2 uv)
{
    // Increased frequency and time dependence for more complex waves
    float t = iTime * 0.8;
    return vec2(sin(uv.x * 10.0 + t * 1.5), cos(uv.y * 8.0 - t * 0.6));
}

vec3 colorFromWave(vec2 w)
{
    // Mapping based on wave coordinates, emphasizing contrast and shifting hue
    float r = 0.1 + 0.5 * sin(w.x * 18.0 + iTime * 0.4);
    float g = 0.5 + 0.4 * cos(w.y * 12.0 - iTime * 0.5);
    float b = 0.2 + 0.2 * sin(w.x * 5.0 + w.y * 3.0 + iTime * 0.7);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    float scale = 3.0;
    uv *= scale;
    // Introduce coupling based on time and noise
    uv.x += sin(uv.y * 7.0 + t * 3.0) * 0.15;
    uv.y += cos(uv.x * 6.0 + t * 1.5) * 0.1;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv = distort(uv);

    // Dynamic flow and rotational field
    float t = iTime * 1.5;
    float flow_field = sin(uv.x * 15.0 + t * 0.5) * 0.4;
    float rot_angle = t * 0.6 + sin(uv.y * 5.0) * 0.5;
    mat2 rot = rotate(rot_angle);
    uv = rot * uv;

    vec2 w = wave(uv);

    vec3 base_color = colorFromWave(w);

    // Layered modulation based on flow and depth
    float flow_mod = sin(uv.x * 10.0 + t * 0.2);
    float depth = uv.y * 2.0 + flow_field * 5.0;

    // Apply layered modulation using the wave phase
    float intensity = 1.0 - abs(sin(w.x * 5.0 + depth * 1.5 + t * 0.3));

    // Refraction effect based on flow
    vec3 refracted_color = base_color * (0.5 + 0.5 * flow_mod);

    // Introduce subtle distortion via depth
    float shift = sin(depth * 3.0) * 0.1;
    refracted_color.r += shift;
    refracted_color.g -= shift * 0.5;
    refracted_color.b += 0.1 * cos(uv.x * 8.0);

    // Final intensity scaling
    vec3 final_col = refracted_color * intensity;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
