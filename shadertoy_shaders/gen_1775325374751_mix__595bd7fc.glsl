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
        sin(uv.x * 5.0 + uv.y * 2.0 + t),
        cos(uv.x * 3.0 - uv.y * 1.5 + t * 0.7)
    );
}

vec3 palette(float t) {
    float r = 0.5 + 0.5*sin(t + iTime * 0.1);
    float g = 0.5 + 0.5*cos(t + iTime * 0.2);
    float b = 0.5 + 0.5*sin(t + iTime * 0.3);
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

    // Apply initial time-based offset
    uv = uv * 2.0 - 1.0;
    uv *= 1.0 + sin(iTime * 0.5) * 0.2;

    // Complex rotation and displacement (from Shader A)
    float angle1 = sin(iTime * 0.3) + uv.x * uv.y * 2.0;
    mat2 rotationMatrix = mat2(cos(angle1), -sin(angle1), sin(angle1), cos(angle1));
    uv *= rotationMatrix;

    float angle2 = iTime * 0.5 + uv.x + uv.y * 0.4;
    uv = rotate(uv, angle2);

    // Apply secondary displacement (from Shader A)
    uv += vec2(
        sin(uv.x * 1.2 + iTime * 0.7),
        cos(uv.y * 1.5 + iTime * 0.6)
    );

    // Apply wave effect (from Shader A)
    uv = wave(uv);

    // Apply geometric distortion (from Shader B)
    uv = distort(uv, iTime);

    // Calculate time-dependent value for palette
    float t = uv.x * 1.5 + uv.y * 0.8 + iTime * 1.2;
    vec3 col = palette(t);

    // Radial and Angular modulation (from Shader B)
    float r = length(uv);
    float angle = atan(uv.y, uv.x);
    float time_factor = iTime * 0.7;

    // Radial modulation
    float radial_shift = 1.0 + 0.5 * sin(r * 5.0 + time_factor * 3.0);
    col.r *= radial_shift;

    // Angular modulation
    float angular_shift = 1.0 + 0.3 * cos(angle * 4.0 + time_factor * 2.0);
    col.g *= angular_shift;

    // Final color interaction based on depth (from Shader B)
    float depth = sin(r * 8.0 + angle * 5.0 + time_factor * 4.0);

    // Mix colors
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
