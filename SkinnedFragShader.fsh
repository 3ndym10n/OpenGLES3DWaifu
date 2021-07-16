#version 310 es

uniform mediump sampler2D sTexture;
// uniform mediump sampler2D sNormalMap;

in highp vec3 worldPosition;
in mediump vec3 vLight;
in mediump vec2 vTexCoord;
in mediump float vOneOverAttenuation;
in highp vec3 transPos;
in highp   vec3 transNormal;
in highp vec3 LightPosition;

layout(location = 0) out mediump vec4 oColor;

const mediump vec4 LightColor=vec4(1.0);
const highp float shininess = 2.0;
const mediump float gamma=1.1;

void main()
{
	// mediump vec3 fNormal = texture(sNormalMap, vTexCoord).rgb;
	/*
	mediump vec3 fNormal = vec3(0.0);
	mediump float fNDotL = clamp(dot((fNormal - 0.5) * 2.0, normalize(vLight)), 0.0, 1.0);
	fNDotL *= vOneOverAttenuation;
	*/
	
	// Diffuse light
    mediump vec3 lightDirection = normalize(LightPosition - transPos);
    highp float brightness = max(dot(LightPosition, lightDirection)*vOneOverAttenuation, 0.05);
    mediump vec3 diffuse = LightColor.xyz * brightness;

    // Specular light
    mediump vec3 specular;
    if (brightness > 0.0) {
        highp vec3 eyeDirection = normalize(-transPos);
        highp vec3 halfVector = normalize(lightDirection + eyeDirection);
        highp float spec = pow(max(dot(transNormal, halfVector)*vOneOverAttenuation, 0.0), shininess);
        specular = spec * LightColor.rgb;
    } else {
        specular = vec3(0.0);
    }
	
	mediump vec3 color = texture(sTexture, vTexCoord).rgb * diffuse+specular;
	color = pow(color, vec3(gamma));
	// 光的衰减
	// mediump vec3 color = texture(sTexture, vTexCoord).rgb * vOneOverAttenuation ;
	// mediump vec3 color = texture(sTexture, vTexCoord).rgb;
#ifndef FRAMEBUFFER_SRGB
	color = pow(color, vec3(0.4545454545)); // Do gamma correction
#endif
	oColor = vec4(color, 1.0);
	// oColor = vec4(1.0);
}
