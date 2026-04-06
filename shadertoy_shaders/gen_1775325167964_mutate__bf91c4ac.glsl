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

vec2 wave(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 0.3) * cos(uv.y * 3.5 + iTime * 0.1), cos(uv.x * 4.0 + iTime * 0.25) * sin(uv.y * 2.5 + iTime * 0.4));
}

vec3 palette(float t)
{
    float r = 0.5 + 0.5 * sin(t * 1.5 + iTime * 0.1);
    float g = 0.5 + 0.5 * cos(t * 0.8 + iTime * 0.2);
    float b = 0.5 + 0.5 * sin(t * 2.0 + iTime * 0.3);
    return vec3(r, g, b);
}

vec2 distort(vec2 uv, float t) {
    float s = sin(t * 0.5) * 0.4 + 0.6;
    float c = cos(t * 0.7) * 0.3 + 0.7;
    return uv * vec2(s, c) + vec2(sin(uv.x * 10.0 + t * 0.5), cos(uv.y * 15.0 - t * 0.6));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = wave(uv);
    uv = distort(uv, iTime);

    // Calculate time-dependent value
    float t = uv.x * 1.5 + uv.y * 0.8 + iTime * 1.2;
    vec3 col = palette(t);

    // Radial effects based on distance
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    float time_factor = iTime * 0.7;

    // Radial modulation
    float radial_shift = 1.0 + 0.5 * sin(r * 5.0 + time_factor * 3.0);
    col.r *= radial_shift;

    // Angular modulation
    float angular_shift = 1.0 + 0.3 * cos(angle * 4.0 + time_factor * 2.0);
    col.g *= angular_shift;

    // Final color interaction
    float depth = sin(r * 8.0 + angle * 5.0 + time_factor * 4.0);

    // Mix colors based on depth and existing palette
    col.b = mix(col.b, depth * 0.5 + 0.5, 0.5);
    col.r = mix(col.r, depth * 0.3, 0.7);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
