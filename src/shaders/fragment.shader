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
    bool isActive;
};

#define MAX_LIGHT 5

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
// uniform sampler2D ourTexture2;
// uniform sampler2D ourTexture3;
uniform Light lights[MAX_LIGHT];
// 3 textures,
// correctTexture = textures[node.textureId]

in vec3 fCol;
in vec3 fPos;
in vec3 fNormal;
in vec3 fViewPos;
in vec2 fTextCoord;
flat in int fTextureId;
// in int textureId

vec3 calculatePointLight(Light light, vec3 normal, vec3 fPos, vec3 fViewPos);

void main()
{
    vec4 texColor = vec4(1.0, 1.0, 1.0, 1.0);

    if (fTextureId == 0) {
        texColor = texture(texture1, fTextCoord);
    } else if (fTextureId == 1) {
        texColor = texture(texture2, fTextCoord);
    } else if (fTextureId == 2) {
        texColor = texture(texture3, fTextCoord);
    }

    vec3 result = vec3(0.0);
    for (int i = 0; i < MAX_LIGHT; i++) {
        if (lights[i].isActive) {
            result += calculatePointLight(lights[i], fNormal, fPos, fViewPos);
        }
    }

    // use var so it does make an error in zig
    result = result * fCol * texColor.rgb;
    fragment = vec4(result, 1.0);
}

vec3 calculatePointLight(Light light, vec3 normal, vec3 fPos, vec3 fViewPos) {
     // ambient
    float ambientStrength = 0.1;
    vec3 ambient = ambientStrength * light.ambient;

    // diffuse
    vec3 norm = normalize(normal);
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

    return (specular + diffuse + ambient);  
}
