#version 330
// uniform mat4 MVP;
uniform mat4 proj;
uniform mat4 view;
in vec3 vCol;
in vec3 vPos;
out vec3 color;
void main()
{
    // gl_Position = MVP * vec4(vPos, 1.0);
    // gl_Position = vec4(vPos, 1.0);
    // gl_Position = view * vec4(vPos, 1.0);
    // gl_Position = proj * vec4(vPos, 1.0);
    gl_Position = proj * view * vec4(vPos, 1.0);
    // gl_Position = vec4(vPos, 1.0);
    color = vCol;
}

