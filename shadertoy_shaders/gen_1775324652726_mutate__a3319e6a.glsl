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
    return vec2(sin(uv.x * 6.0 + iTime * 1.5) * cos(uv.y * 2.5 + iTime * 0.7), cos(uv.x * 4.5 + iTime * 2.0) * sin(uv.y * 3.0 + iTime * 1.1));
}

vec3 palette(float t)
{
    float r = sin(t * 1.2 + iTime * 0.15) * 0.5 + 0.5;
    float g = cos(t * 1.5 + iTime * 0.2) * 0.5 + 0.5;
    float b = sin(t * 1.0 + iTime * 0.3) * 0.5 + 0.5;

    vec3 base = vec3(r, g, b);

    vec3 offset = vec3(0.1, 0.3, 0.5);
    vec3 shift = vec3(sin(t * 5.0 + iTime * 0.5), cos(t * 7.0 + iTime * 0.8), sin(t * 3.0 + iTime * 1.0));

    return base + offset * cos(3.14159 * (shift * 0.5));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = uv * vec2(5.0, 3.0) - vec2(1.0, 1.5);

    float flow = iTime * 0.8;
    float dist = length(uv);

    // Complex flow calculation
    float angle_x = flow + sin(uv.x * 7.0 + flow * 1.5) * 1.5;
    float angle_y = flow + cos(uv.y * 5.0 + flow * 0.5) * 1.0;

    // Apply rotational flow
    mat2 rotationMatrix = mat2(cos(angle_x), -sin(angle_x), sin(angle_x), cos(angle_x));
    uv = rotationMatrix * uv;

    uv = wave(uv);

    // Distortion based on distance and flow
    float warp = sin(dist * 20.0 + flow * 3.0) * 0.3 + 0.5;

    vec3 col = palette(warp + sin(uv.x * 8.0 + iTime * 1.2) * 0.5);

    // Add dynamic offset based on rotated coordinates
    float r = sin(uv.x * 5.0 + iTime * 1.5) * 0.7;
    float g = cos(uv.y * 6.0 + iTime * 0.9) * 0.7;
    float b = sin(uv.x * 3.0 + iTime * 0.5) * 0.3;

    col = mix(col, vec3(r, g, b), 0.5 + uv.y * 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
