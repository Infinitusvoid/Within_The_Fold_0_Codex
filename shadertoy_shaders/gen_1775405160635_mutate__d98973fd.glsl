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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.0,0.25,0.6)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Convert to polar coordinates
    float a = atan(uv.y,uv.x);
    float r = length(uv);

    // Create a dynamic displacement factor based on time and position
    float flow = a * 10.0 + iTime * 0.5;

    // Quantize the flow to create bands
    float n = 16.0;
    float q = floor((flow / 6.28318 + 0.5) * n) / n;

    // Modulate the pulse based on radius and flow
    float pulse = 0.5 + 0.5*sin(10.0*r - 3.0*iTime + q*12.0);

    // Use the pulse to control the brightness and apply a radial gradient
    float intensity = smoothstep(0.3, 0.8, pulse * 0.7 + 0.2);

    // Calculate color using the palette offset by time and intensity
    vec3 base_color = pal(q + 0.1*iTime);
    vec3 col = base_color * intensity * exp(-r * 0.5);

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
