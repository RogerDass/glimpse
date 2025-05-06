//
//  modelShader.metal
//  Glimpse
//
//  Created by Roger D on 2025-04-29.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
	float3 position [[attribute(0)]];
	float3 normal   [[attribute(1)]];
	float2 uv       [[attribute(2)]];
};

struct InstanceData {
	float4x4 modelMatrix;
};

struct FrameUniforms {
	float4x4 viewProjectionMatrix;
};

struct VertexOut {
	float4 position [[position]];
	float3 worldPos;
	float3 normal;
	float4 color;
	float2 uv;
};

vertex VertexOut vertex_main_model(
	VertexIn in [[stage_in]],
	constant InstanceData* instanceBuffer [[buffer(1)]],
	constant float4* colorBuffer [[buffer(2)]],
	constant FrameUniforms& frame [[buffer(3)]],
	uint instanceID [[instance_id]]
) {
	VertexOut out;

	float4x4 modelMatrix = instanceBuffer[instanceID].modelMatrix;
	float4 worldPosition = modelMatrix * float4(in.position, 1.0);

	out.position = frame.viewProjectionMatrix * worldPosition;
	out.worldPos = worldPosition.xyz;

	// transform normal using upper-left 3x3 of model matrix
	float3x3 normalMatrix = float3x3(
		modelMatrix[0].xyz,
		modelMatrix[1].xyz,
		modelMatrix[2].xyz
	);
	out.normal = normalize(normalMatrix * in.normal);

	out.color = colorBuffer[instanceID]; // optional: instance tint
	out.uv = in.uv;

	return out;
}

fragment float4 fragment_main_model(VertexOut in [[stage_in]]) {
	// simple lambert diffuse
	float3 lightDir = normalize(float3(0.5, 1.0, 0.5));
	float lighting = max(dot(in.normal, lightDir), 0.0);

	// base color could come from texture (optional)
	float3 baseColor = in.color.rgb;

	return float4(baseColor * lighting, 1.0);
}

