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

vec3 pal(float t)
{
    return 0.55 + 0.45*cos(6.28318*(vec3(0.08,0.35,0.67)+t));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;

    // Polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Introduce radial depth based on distance and angular deviation
    float z = 1.0 / (r * 1.5 + 0.5*sin(a * 4.0));

    // Use time and coordinates to generate complex wave interference
    float f1 = sin(10.0*a + 5.0*r - 1.0*iTime);
    float f2 = cos(15.0*a + 3.0*z * 2.0 + 2.0*iTime); 

    // Generate bands and rings based on radial oscillation
    float bands = smoothstep(0.2, 0.0, abs(f1 * f2 * 1.5));
    float ring = smoothstep(0.5, 0.0, abs(sin(r * 20.0 + iTime * 0.8)));

    // Calculate color modulation using depth (z) and angle (a)
    vec3 col = pal(0.2 * iTime + 0.5 * z + 0.3 * f1);

    // Combine modulation factors, applying stronger radial falloff
    float modulation = 0.15 + 3.0 * bands + 0.5 * ring;
    col *= modulation;
    col *= exp(-3.0 * r * r * z * 0.5); // Stronger, depth-dependent radial falloff

    fragColor = vec4(col, 1.0);
}

void main()
{
    vec4 codexMainImageColor = vec4(0.0);
    mainImage(codexMainImageColor, gl_FragCoord.xy);
    FragColor = codexMainImageColor;
}
