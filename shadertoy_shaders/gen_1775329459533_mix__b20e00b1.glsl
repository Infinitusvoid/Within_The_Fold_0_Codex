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
    float t = iTime * 0.8;
    // Combine timing shifts
    return vec2(sin(uv.x * 9.0 + t * 1.5), cos(uv.y * 7.0 - t * 0.9));
}

vec3 colorFromWave(vec2 w)
{
    // Mix modulation styles
    float r = 0.1 + 0.5 * sin(w.x * 20.0 + iTime * 0.4);
    float g = 0.5 + 0.4 * cos(w.y * 12.0 - iTime * 0.5);
    float b = 0.2 + 0.2 * sin(w.x * 5.0 + w.y * 3.0 + iTime * 0.7);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv)
{
    float t = iTime * 0.4;
    // Integrate motion and scale effects from B
    float scale = 1.0 + 0.04 * sin(t + uv.x * 15.0);
    float shift = 1.0 + 0.03 * cos(t + uv.y * 10.0);
    uv.x *= scale;
    uv.y *= shift;
    // Add coupling derived from A's distortion structure
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

    // Determine underlying wave structure
    vec2 w = wave(uv);
    vec3 base_color = colorFromWave(w);

    // Distortion and rotational base
    uv = distort(uv);

    // Global flow and rotational field
    float t = iTime * 1.5;
    float flow_field = sin(uv.x * 15.0 + t * 0.8) * 0.5;
    float rot_angle = t * 0.6 + sin(uv.y * 5.0) * 0.5;
    mat2 rot = rotate(rot_angle);
    uv = rot * uv;

    // Layered modulation derived dynamically based on flow/coords
    float flow_mod = sin(uv.x * 10.0 + t * 0.3);
    float depth = uv.y * 2.5 + flow_field * 4.0;

    // Intensity modulation: emphasis on noise interacting with modulated depth
    float intensity = 1.0 - abs(sin(w.x * 7.0 + depth * 1.5 + t * 0.5)) * 0.5;

    // Calculate refracted colors and applying flow complexity
    vec3 refracted_color = base_color * (0.5 + 0.5 * flow_mod);

    // Subtle depth visualization offset
    float shift = sin(depth * 3.0) * 0.15;
    refracted_color.r += shift * 0.5;
    refracted_color.g -= shift;
    refracted_color.b += 0.1 * cos(uv.x * 10.0);

    // Final enhancement based on frequency echoes
    float dx_term = uv.x * 8.0 * sin(iTime * 0.1);
    vec3 final_col = refracted_color;

    final_col.r = sin(final_col.g * 1.5 + iTime * 0.55);
    final_col.g = cos(final_col.r * 1.2 + uv.y * 6.0 + t * 0.3);
    final_col.b = 0.5 + 0.5 * sin(w.x * 1 + depth / 5.0 + iTime * 0.2);

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
