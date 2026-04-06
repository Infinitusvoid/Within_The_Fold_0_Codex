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
    float a = atan(uv.y,uv.x), r = length(uv);
    float n = 16.0;
    float q = floor((a/6.28318 + 0.5)*n)/n;

    // Angle and Time based modulation
    float angle_factor = a * 0.5 + iTime * 0.2;
    float pulse = 0.5 + 0.5*sin(8.0*r - 3.0*iTime + q*12.0 + angle_factor);
    float fan = smoothstep(0.4,0.9,pulse);

    // Radial decay and complex scaling
    float dist_scale = 1.0 / (r * 0.3 + 0.1);
    vec3 col = pal(q + 0.1*iTime) * fan * exp(-r * dist_scale);

    // Add a slight rotation effect based on angle
    float rotation = (a + iTime * 0.5) * 0.1;
    col.rgb = mix(col.rgb, col.rgb * cos(rotation * 3.14159), 0.5);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
