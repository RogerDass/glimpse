//
//  shaders.metal
//  TriangleExample
//
//  Created by Roger D on 2025-03-13.
//

#include <metal_stdlib>

using namespace metal;

vertex float4 vertex_main(const device float2 * vertices[[buffer(0)]], const uint vid[[vertex_id]])
{
	return float4(vertices[vid], 0, 1);
}

fragment float4 fragment_main()
{
	return float4(1.0, 0, 1.0, 1);
}

