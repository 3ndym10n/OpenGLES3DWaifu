#version 310 es

uniform mediump sampler2D sTexture;
uniform highp sampler2D s_shadowmap;
uniform int isPassLight;

in highp vec3 worldPosition;
in mediump vec3 vLight;
in mediump vec2 vTexCoord;
in mediump float vOneOverAttenuation;
in highp vec3 transPos;
in highp   vec3 transNormal;
in highp vec3 LightPosition;
in highp vec4 v_shadowcoord;

layout(location = 0) out mediump vec4 oColor;

const mediump vec4 LightColor=vec4(1.0);
const highp float shininess = 2.0;
const mediump float gamma=1.1;

void main()
{
    highp vec4 shadow_coord = v_shadowcoord.xyzw / v_shadowcoord.w;
    shadow_coord=shadow_coord*0.5+0.5;
	if (1 == isPassLight)
	{
        // oColor=vec4((shadow_coord.zzz-0.965)*50.0,1.0);
		return;
	}
	
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

	 // 泊松采样
    highp vec2 poissonDisk[4] = vec2[](
        vec2(-0.94201624, -0.39906216),
        vec2(0.94558609, -0.76890725),
        vec2(-0.0941848101, -0.92938870),
        vec2(0.34495938, 0.29387760)
    );
    mediump float shadow = 1.0;
    for (int i = 0; i < 4; ++i) {
        // 采样深度纹理，然后比较z值
        highp vec4 tex_col = texture(s_shadowmap, shadow_coord.xy + poissonDisk[i]/3000.0);
        if (tex_col.r < shadow_coord.z-0.00002) {
            shadow -= 0.2;
        }
    }
	
	mediump vec3 color = (texture(sTexture, vTexCoord).rgb * diffuse+specular)*shadow;
	color = pow(color, vec3(gamma));
#ifndef FRAMEBUFFER_SRGB
	color = pow(color, vec3(0.4545454545)); // Do gamma correction
#endif
	oColor = vec4(color, 1.0);
}
