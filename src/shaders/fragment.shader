#version 330

// in vec3 color;
out vec4 fragment;

// uniform vec3 ambientColor;
// uniform vec3 diffuseColor;
// uniform vec3 specularColor;
// uniform vec3 lightPos;
// uniform float lightStrength;

struct Light {
    vec3 position;
    float strength;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;
};
uniform Light light;

in vec3 fCol;
in vec3 fPos;
in vec3 fNormal;
in vec3 fViewPos;

void main()
{
    // ambient
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * light.ambient;

    // diffuse
    vec3 norm = normalize(fNormal);
    vec3 lightDir = normalize(light.position - fPos);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * light.diffuse * light.strength;

    // specular
    vec3 specular = vec3(0.0);
    if (diff > 0.0) {
        float specularStrength = 10;
        vec3 viewDir = normalize(fViewPos - fPos);
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 15);
        specular = specularStrength * spec * light.specular;
    }

    // attenuation
    float distance = length(light.position - fPos);
    float attenuation = 1.0 / (light.constant + light.linear * distance + 
                        light.quadratic * (distance * distance));

    diffuse  *= attenuation;
    ambient  *= attenuation;
    specular *= attenuation;
    vec3 result = (specular  + diffuse + ambient) * fCol;
    vec3 color = result;

    fragment = vec4(color, 1.0);
}

