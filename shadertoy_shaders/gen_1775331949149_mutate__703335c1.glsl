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

vec2 waveA(vec2 uv)
{
    return uv + vec2(
        sin(uv.x * 4.0 + iTime * 0.8),
        cos(uv.y * 3.5 - iTime * 0.5) * 0.09
    );
}

vec2 waveB(vec2 uv)
{
    return vec2(sin(uv.x * 10.0 + iTime * 1.2), cos(uv.y * 15.0 - iTime * 0.6));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 0.6 + iTime * 0.4);
    float g = 0.4 + 0.4 * cos(t * 1.3 - iTime * 0.25);
    float b = 0.1 + 0.7 * sin(t * 2.0 + iTime * 0.1);
    return vec3(r, g, b);
}

vec2 ripple(vec2 uv)
{
    float r = sin(uv.x * 6.0 + iTime * 1.8);
    float g = cos(uv.y * 4.5 + iTime * 2.2);
    return vec2(r * 0.5 + 0.5, g * 0.5 + 0.5);
}

vec3 flowPalette(float t, vec2 uv)
{
    float base = sin(uv.x * 3.5 + t * 1.5);
    float shift = cos(uv.y * 4.0 + t * 2.0);
    float intensity = pow(abs(base * shift), 2.5) * 12.0;

    vec3 color = vec3(0.1, 0.9, 0.1);
    color.r = mix(color.r, 0.95, intensity * 0.6);
    color.g = mix(color.g, 0.15, intensity * 0.7);
    color.b = mix(color.b, 0.3, intensity * 0.5);
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    // Apply initial coordinate transformation
    uv = uv * vec2(5.0, 3.0) - vec2(0.25, 0.0);

    // Combine wave distortions
    uv = waveB(uv);
    uv = waveA(uv);

    // Apply ripple distortion
    vec2 d = ripple(uv);
    uv = uv + d * 0.4;

    // Harmonic input for coloring based on combined movement
    float timeFactor = sin(uv.x * 5.0 + iTime * 1.5) + cos(uv.y * 2.5 + iTime * 1.0);
    vec3 dynamic_color = flowPalette(timeFactor * 2.5, uv);

    // Flow definition based on spatial differences
    float flow_x = sin(uv.x * 6.0 + iTime * 0.3);
    float flow_y = cos(uv.y * 5.0 + iTime * 0.9);

    float interaction_mod = pow(flow_x * flow_y, 3.0);

    // Apply color modulation based on flow intensity
    vec3 final_color = mix(vec3(0.0, 0.2, 0.4), vec3(1.0, 0.7, 0.5), interaction_mod * 2.0);

    fragColor = vec4(dynamic_color * final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
