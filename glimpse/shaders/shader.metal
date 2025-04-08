//
//  shaders.metal
//  TriangleExample
//
//  Created by Roger D on 2025-03-13.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
	float2 position [[attribute(0)]];
};

struct InstanceData {
	float4x4 modelMatrix;
};

struct VertexOut {
	float4 position [[position]];
	float4 color;
};

vertex VertexOut vertex_main(
	VertexIn in [[stage_in]],
	constant InstanceData* instanceBuffer [[buffer(1)]],
	constant float4* colorBuffer [[buffer(2)]],
	uint instanceID [[instance_id]])
{
	VertexOut out;
	float4 pos = float4(in.position, 0.0, 1.0);
	out.position = instanceBuffer[instanceID].modelMatrix * pos;
	out.color = colorBuffer[instanceID];
	return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
	return in.color;
}
