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
    float t = iTime * 1.2;
    // Increase complexity and frequency interaction
    float f1 = uv.x * 10.0 + t * 2.0;
    float f2 = uv.y * 15.0 - t * 2.5;
    return vec2(sin(f1) * 0.5 + cos(f2) * 0.5, cos(f1) * 0.5 - sin(f2) * 0.5);
}

vec3 colorFromWave(vec2 w)
{
    // Use w.x and w.y to derive intensity and hue shifts
    float r = 0.15 + 0.6 * sin(w.x * 30.0 + iTime * 0.5);
    float g = 0.4 + 0.5 * cos(w.y * 25.0 - iTime * 0.3);
    float b = 0.25 + 0.3 * sin(w.x * 10.0 + w.y * 5.0 + iTime * 0.7);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.5;
    // More aggressive scaling and shifting
    float scale = 1.0 + 0.06 * sin(t + uv.x * 20.0);
    float shift = 1.0 + 0.05 * cos(t + uv.y * 12.0);
    uv.x *= scale;
    uv.y *= shift;
    // Increased coupling
    uv.x += sin(uv.y * 10.0 + t * 4.0) * 0.2;
    uv.y += cos(uv.x * 8.0 + t * 2.5) * 0.15;
    return uv;
}

mat2 rotate(float a)
{
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Determine underlying wave structure
    vec2 w = wave(uv);
    vec3 base_color = colorFromWave(w);

    // Distortion and rotational base
    uv = distort(uv);

    // Global flow and rotational field
    float t = iTime * 2.0;
    // Enhanced flow field interaction
    float flow_field = sin(uv.x * 25.0 + t * 1.0) * 0.7;
    float rot_angle = t * 0.8 + sin(uv.y * 8.0) * 0.6;
    mat2 rot = rotate(rot_angle);
    uv = rot * uv;

    // Layered modulation derived dynamically based on flow/coords
    float flow_mod = sin(uv.x * 15.0 + t * 0.2);
    float depth = uv.y * 3.0 + flow_field * 5.0;

    // Intensity modulation: emphasize contrast based on wave magnitude and depth
    float intensity = 1.0 - abs(sin(w.x * 40.0 + depth * 2.0 + t * 0.3)) * 0.6;

    // Calculate refracted colors and applying flow complexity
    vec3 refracted_color = base_color * (0.5 + 0.5 * flow_mod);

    // Subtle depth visualization offset
    float shift = sin(depth * 4.0) * 0.2;
    refracted_color.r += shift * 0.8;
    refracted_color.g -= shift * 1.2;
    refracted_color.b += 0.2 * cos(uv.x * 15.0);

    // Final enhancement based on frequency echoes
    float dx_term = uv.x * 12.0 * sin(iTime * 0.15);
    vec3 final_col = refracted_color;

    // Introduce chromatic interaction
    final_col.r = sin(final_col.g * 1.8 + iTime * 0.6);
    final_col.g = cos(final_col.r * 1.5 + uv.y * 7.0 + t * 0.4);
    final_col.b = 0.5 + 0.4 * sin(w.x * 1.5 + depth / 6.0 + iTime * 0.3);

    // Apply dynamic layering scale
    final_col = final_col * intensity;

    fragColor = vec4(final_col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
