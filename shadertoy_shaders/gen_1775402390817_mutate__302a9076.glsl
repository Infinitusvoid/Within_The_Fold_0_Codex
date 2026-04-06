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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.05,0.35,0.75)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Calculate polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Modify spatial calculation using sine flow
    float flow = sin(r * 10.0 + a * 3.0) * 2.0;

    // Introduce time-based distortion
    float time_influence = iTime * 0.5;

    // Calculate a depth/layer value based on flow and time
    float z = flow * 1.5 + time_influence;
    z = fract(z * 3.0);

    // Use the palette function based on distorted coordinates
    vec3 color_offset = pal(0.1 + 0.5*z + 0.1*r);

    // Modulation based on radial distance and flow
    float mask = smoothstep(0.5, 0.4, abs(sin(r * 5.0 + time_influence * 2.0)));

    // Apply radial falloff and flow influence
    vec3 col = color_offset * mask * exp(-5.0 * r * r + flow * 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
