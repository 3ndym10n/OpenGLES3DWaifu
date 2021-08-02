#version 310 es

/*
	If the current vertex is affected by bones then the vertex position and
	normal will be transformed by the bone matrices. Each vertex wil have up
	to 4 bone indices (inBoneIndex) and bone weights (inBoneWeights).

	The indices are used to index into the array of bone matrices
	(BoneMatrixArray) to get the required bone matrix for transformation. The
	amount of influence a particular bone has on a vertex is determined by the
	weights which should always total 1. So if a vertex is affected by 2 bones
	the vertex position in world space is given by the following equation:

	position = (BoneMatrixArray[Index0] * inVertex) * Weight0 +
	           (BoneMatrixArray[Index1] * inVertex) * Weight1

	The same proceedure is applied to the normals but the translation part of
	the transformation is ignored.

	After this the position is multiplied by the view and projection matrices
	only as the bone matrices already contain the model transform for this
	particular mesh. The two-step transformation is required because lighting
	will not work properly in clip space.
*/

layout(location=0) in highp vec3 inVertex;
layout(location=1) in highp vec3 inNormal;
layout(location=2) in highp vec3 inTangent;
layout(location=3) in highp vec3 inBiNormal;
layout(location=4) in highp vec2 inTexCoord;
layout(location=5) in highp vec4 inBoneWeights;
layout(location=6) in highp vec4 inBoneIndex;
// layout(location=5) in highp float inBoneWeights;
// layout(location=6) in highp uint inBoneIndex;

struct Bone{
	highp mat4 boneMatrix;
	highp mat3 boneMatrixIT;
};

layout (std140, binding = 0) uniform MyUBlock
{
	highp mat4 ViewProjMatrix;
	highp vec3 LightPos;
};

layout (std140, binding = 0) buffer MyBBlock
{
    Bone bones[];
};

uniform int BoneCount;	// 每vertex受几个bone影响
uniform highp mat4 light_ViewProjMatrix;
uniform int isPassLight;

out highp vec3 vLight;
out mediump vec2 vTexCoord;

out highp vec3 worldPosition;
out mediump float vOneOverAttenuation;

out highp vec3 transPos;	//未归一化的世界三维坐标
out highp vec3 LightPosition;
out highp   vec3 transNormal;
out highp vec4 v_shadowcoord;

const highp vec3 LP=vec3(1000.0);	// 自己设置的灯光位置（世界坐标）

void main()
{
	/* Bias matrix used to map values from a range <-1, 1> (eye space coordinates) to <0, 1> (texture coordinates). */
    const mat4 bias = mat4(0.5, 0.0, 0.0, 0.0,
                          0.0, 0.5, 0.0, 0.0,
                          0.0, 0.0, 0.5, 0.0,
                          0.5, 0.5, 0.5, 1.0);
	
	// On PowerVR GPUs it is possible to index the components of a vector
	// with the [] operator. However this can cause trouble with PC
	// emulation on some hardware so we "rotate" the vectors instead.
	// mediump ivec4 boneIndex = ivec4(inBoneIndex);
	// mediump vec4 boneWeights = inBoneWeights;
	mediump ivec4 boneIndex = ivec4(inBoneIndex);
	mediump vec4 boneWeights = inBoneWeights;

	mediump vec3 worldTangent = vec3(0, 0, 0);
	mediump vec3 worldBiNormal = vec3(0, 0, 0);

	highp vec4 position = vec4(0, 0, 0, 0);
	mediump vec3 worldNormal = vec3(0, 0, 0);

	for (mediump int i = 0; i < BoneCount; ++i)
	{
		Bone b = bones[boneIndex.x];
		position += b.boneMatrix * vec4(inVertex, 1.0) * boneWeights.x;
		worldNormal += b.boneMatrixIT  * inNormal * boneWeights.x;

		worldTangent += b.boneMatrixIT * inTangent * boneWeights.x;
		worldBiNormal += b.boneMatrixIT * inBiNormal * boneWeights.x;

		// "rotate" the vector components 不断循环位移
		boneIndex = boneIndex.yzwx;
		boneWeights = boneWeights.yzwx;
	}
	transPos=position.xyz;	//未归一化的世界三维位置矢量

	worldPosition = position.xyz / position.w;	//归一化世界四维位置矢量

	if (1==isPassLight)
		gl_Position = light_ViewProjMatrix * position;
	else
		gl_Position = ViewProjMatrix * position;
	v_shadowcoord=light_ViewProjMatrix*position;	//未归一化

	// lighting
	// 这里没有用主程序传入的灯光位置 LightPos
	mediump vec3 tmpLightDir = LP - position.xyz;
	mediump float light_distance = length(tmpLightDir);
	tmpLightDir /= light_distance;
	LightPosition=LP;
	
	// 光线衰减
	vOneOverAttenuation = 1.0 / (1.0 + 0.05 * light_distance+0.0005 * light_distance * light_distance);

	vLight.x = dot(normalize(worldTangent), tmpLightDir);
	vLight.y = dot(normalize(worldBiNormal), tmpLightDir);
	vLight.z = dot(normalize(worldNormal), tmpLightDir);

	// Pass through texcoords
	vTexCoord = inTexCoord;

}
