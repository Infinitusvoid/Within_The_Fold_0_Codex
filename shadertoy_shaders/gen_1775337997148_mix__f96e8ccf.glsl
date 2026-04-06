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

vec3 pal(float t){ return 0.55 + 0.45*cos(6.28318*(vec3(0.02,0.34,0.68)+t)); }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;

    // Variables from Shader A (Radial structure)
    float r = length(uv), a = atan(uv.y,uv.x);
    float petals = cos(6.0*a + 1.5*sin(iTime + 6.0*r));
    float d = r - (0.28 + 0.08*petals);
    float fill = smoothstep(0.02,0.0,d);
    float line = smoothstep(0.03,0.0,abs(d));

    // Variables from Shader B (Wave structure and time)
    float z = 1.0/(length(uv)+0.25) + iTime*1.5;
    float y1 = 0.22*sin(3.0*z + iTime);
    float y2 = 0.22*sin(3.0*z + iTime + 3.14159);
    float l1 = smoothstep(0.05,0.0,abs(uv.y-y1));
    float l2 = smoothstep(0.05,0.0,abs(uv.y-y2));

    // Combine masking logic (A's fill/line mixed with B's side masks)
    float mask = (0.25*fill + 1.8*line) * l1 + (0.5*l2);

    // Apply combined coloring based on z modulation
    vec3 col = pal(0.1*z) * mask;
    col += pal(0.1*z+0.5) * (1.0 - l1) * l2;

    // Final scaling (from Shader B)
    col *= 0.7/(1.0+2.0*r);

    fragColor = vec4(col,1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
