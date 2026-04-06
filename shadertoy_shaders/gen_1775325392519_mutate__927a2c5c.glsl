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

vec2 waveC(vec2 uv)
{
    return vec2(sin(uv.x * 5.0 + iTime * 0.5), cos(uv.y * 5.0 + iTime * 0.7));
}

vec2 waveD(vec2 uv)
{
    return vec2(sin(uv.y * 6.0 + iTime * 0.3), cos(uv.x * 3.5 + iTime * 0.6));
}

vec3 palette(float t)
{
    return vec3(0.1 + 0.7 * sin(t * 0.5 + iTime * 0.1), 0.5 + 0.5 * cos(t * 0.4 + iTime * 0.2), 0.9 - 0.5 * sin(t * 0.6 + iTime * 0.3));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    uv = uv * vec2(2.0, 1.0) - vec2(0.5, 0.0);

    float angle = iTime * 0.5 + sin(uv.x * 10.0 + iTime * 0.2) * cos(uv.y * 5.0) * 0.3;
    mat2 rotationMatrix = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    uv = rotationMatrix * uv;

    uv = waveC(uv);
    uv = waveD(uv);

    float t = uv.x * 2.0 + uv.y * 1.5 + iTime * 1.5;
    vec3 base_color = palette(t);

    float flow_x = sin(uv.x * 8.0 + iTime * 1.0);
    float flow_y = cos(uv.y * 12.0 + iTime * 0.8);

    // Introduce a complex distortion based on the interaction of flows
    float distortion = flow_x * flow_y * 1.5;

    // Modify the color based on flow and position
    vec3 final_color = base_color * (0.5 + 0.5 * sin(uv.x * 5.0 + iTime * 0.5 + distortion));

    fragColor = vec4(final_color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
