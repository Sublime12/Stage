#version 330
// uniform mat4 MVP;
uniform mat4 proj;
uniform mat4 view;

// uniform vec3 lightColor;
// uniform vec3 lightPos;
// uniform float lightStrength;

in vec3 vCol;
in vec3 vPos;
in vec3 normal;

out vec3 fCol;
out vec3 fPos;
out vec3 fNormal;
// out vec3 color;

void main()
{
    // vec3 norm = normalize(normal);
    // vec3 lightDir = normalize(lightPos - vPos);
    // float diff = max(dot(norm, lightDir), 0.0);
    // vec3 diffuse = diff * lightColor * lightStrength;
    // vec3 result = diffuse * vCol + 0.2;
    // color = result;
    fCol = vCol;
    fPos = vPos;
    fNormal = normal;
    gl_Position = proj * view * vec4(vPos, 1.0);
}

