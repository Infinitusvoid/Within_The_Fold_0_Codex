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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.1,0.4,0.7)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    float dist = length(uv);
    float p = 1.0 / (dist * 2.0 + 1.0);

    float t = iTime * 0.8 + uv.x * 5.0;

    // Introduce higher frequency modulation and sharper transitions
    float r = sin(t * 2.0 + uv.y * 5.0) * 0.5 + 0.5;
    float g = cos(t * 2.2 + uv.y * 4.5) * 0.5 + 0.5;
    float b = sin(t * 2.5 + uv.x * 3.0) * 0.5 + 0.5;

    // Mix colors using the modulation function
    vec3 color = pal(p * 5.0 + t) * r + pal(p * 5.0 + t + 0.1) * g + pal(p * 5.0 + t + 0.2) * b;

    // Apply spatial falloff based on distance and time
    float ambient = 0.1 + p * 0.8;
    color *= ambient * (1.0 + sin(t * 1.5));

    fragColor = vec4(color, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
