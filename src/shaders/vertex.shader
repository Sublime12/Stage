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
in vec2 textCoord;
in int textureId;

out vec3 fCol;
out vec3 fPos;
out vec3 fNormal;
out vec3 fViewPos;
out vec2 fTextCoord;
flat out int fTextureId;
// out vec3 color;

void main()
{
    // TODO: expensive to calculate inverse on every vertex
    // calculate it in the cpu code
    mat4 inverseView = inverse(view);
    fViewPos = inverseView[3].xyz;
    fCol = vCol;
    fPos = vPos;
    fNormal = normal;
    fTextCoord = textCoord;
    fTextureId = textureId;
    gl_Position = proj * view * vec4(vPos, 1.0);
}

