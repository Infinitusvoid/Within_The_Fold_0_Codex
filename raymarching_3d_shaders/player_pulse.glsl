#version 330 core
in vec2 TexCoord;
in vec3 WorldPos;
in vec3 LocalPos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform vec3 uColor;
uniform float time;
uniform float iTime;
uniform float iTimeDelta;
uniform int iFrame;
uniform vec4 iMouse;

uniform vec3 uCamPos;
uniform vec3 iPlayerPos;
uniform vec3 uPlayerPos;
uniform vec3 uCubePos;

uniform vec2 uResolution;
uniform vec3 iResolution;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdRoundBox(vec3 p, vec3 b, float r)
{
    vec3 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

mat2 rot2(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

vec3 triPlanar(sampler2D texA, sampler2D texB, vec3 p, vec3 n)
{
    vec3 blend = pow(abs(n), vec3(4.0));
    blend /= max(dot(blend, vec3(1.0)), 0.0001);

    vec3 xColor = mix(texture(texA, p.yz * 1.8).rgb, texture(texB, p.yz * 0.9).rgb, 0.45);
    vec3 yColor = mix(texture(texA, p.xz * 1.8).rgb, texture(texB, p.xz * 1.2).rgb, 0.55);
    vec3 zColor = mix(texture(texA, p.xy * 1.8).rgb, texture(texB, p.xy * 0.8).rgb, 0.35);
    return xColor * blend.x + yColor * blend.y + zColor * blend.z;
}

float mapScene(vec3 p)
{
    vec3 cubeCenter = model[3].xyz + vec3(0.5);
    vec3 q = p - cubeCenter;

    vec3 playerDir = normalize((uPlayerPos - cubeCenter) + vec3(0.001));
    float pulse = 0.18 + 0.06 * sin(iTime * 2.0 + dot(uCubePos, vec3(3.1, 2.7, 1.9)));

    vec3 orbOffset = playerDir * (0.10 + 0.05 * sin(iTime * 1.1 + q.y * 6.0));
    float orb = sdSphere(q - orbOffset, pulse);

    q.xz *= rot2(iTime * 0.6 + uCubePos.x * 0.4);
    q.xy *= rot2(iTime * 0.25 + uCubePos.z * 0.2);
    float shell = sdRoundBox(q, vec3(0.37), 0.08);

    return min(orb, shell);
}

vec3 calcNormal(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy) - mapScene(p - e.xyy),
        mapScene(p + e.yxy) - mapScene(p - e.yxy),
        mapScene(p + e.yyx) - mapScene(p - e.yyx)
    ));
}

void main()
{
    vec3 ro = uCamPos;
    vec3 rd = normalize(WorldPos - ro);

    float t = 0.0;
    float d = 0.0;
    bool hit = false;

    for (int i = 0; i < 96; ++i)
    {
        vec3 p = ro + rd * t;
        d = mapScene(p);

        if (d < 0.001)
        {
            hit = true;
            break;
        }

        t += d * 0.85;
        if (t > 12.0)
        {
            break;
        }
    }

    vec3 color = vec3(0.02, 0.03, 0.05);

    if (hit)
    {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);

        vec3 lightDir = normalize((iPlayerPos - p) + vec3(0.4, 0.8, -0.3));
        float diffuse = max(dot(n, lightDir), 0.0);
        float rim = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);

        vec3 surface = triPlanar(iChannel0, iChannel1, p - (uCubePos + 0.5), n);
        vec3 accent = 0.4 + 0.6 * abs(sin(vec3(0.3, 0.8, 1.2) * iTime + uCubePos));

        color = surface * (0.22 + 0.85 * diffuse);
        color *= mix(vec3(1.0), accent * max(uColor, vec3(0.15)), 0.55);
        color += rim * accent;
    }
    else
    {
        vec2 uv = gl_FragCoord.xy / max(iResolution.xy, vec2(1.0));
        float scan = 0.5 + 0.5 * sin(uv.y * 120.0 + float(iFrame) * 0.05);
        float focal = clamp(projection[1][1] * 0.15, 0.0, 1.0);
        color = mix(color, vec3(0.08, 0.15, 0.22) * (0.5 + 0.5 * scan), focal);
    }

    FragColor = vec4(sqrt(max(color, vec3(0.0))), 1.0);
}
