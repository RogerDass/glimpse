//
//  GlimpseMath.swift
//  Glimpse
//
//  Created by Roger D on 2025-03-17.
//


import simd

public class GlimpseMath {

	/// Returns a perspective projection matrix (right-handed)
	///  Parameters:
	///   fovyRadians: Vertical field of view in radians
	///   aspect: Aspect ratio (width / height)
	///   nearZ: Near plane distance
	///   farZ: Far plane distance
	///  Returns: Perspective matrix as float4x4
	public static func perspective(
		fovyRadians: Float,
		aspect: Float,
		nearZ: Float,
		farZ: Float) -> float4x4
	{
		let yScale = 1.0 / tan(fovyRadians * 0.5)
		let xScale = yScale / aspect
		let zRange = farZ - nearZ
		let zScale = -(farZ + nearZ) / zRange
		let wzScale = -2.0 * farZ * nearZ / zRange
		
		return float4x4([
			SIMD4<Float>(xScale,    0,      0,    0),
			SIMD4<Float>(    0, yScale,     0,    0),
			SIMD4<Float>(    0,    0,   zScale,  -1),
			SIMD4<Float>(    0,    0,  wzScale,   0)
		])
	}


	/// Returns a right-handed look-at matrix for a camera
	///  Parameters:
	///   eye: Camera position
	///   center: The point the camera is looking at
	///   up: Up direction for the camera
	///  Returns: A float4x4 that transforms world space into this camera space
	public static func lookAt(
		eye: SIMD3<Float>,
		center: SIMD3<Float>,
		up: SIMD3<Float>) -> float4x4
	{
		let f = simd_normalize(center - eye)
		let s = simd_normalize(simd_cross(f, up))
		let u = simd_cross(s, f)

		let translation = SIMD3<Float>(
			-simd_dot(s, eye),
			-simd_dot(u, eye),
			-simd_dot(f, eye)
		)

		return float4x4([
			SIMD4<Float>(s.x,  u.x,  -f.x,  0),
			SIMD4<Float>(s.y,  u.y,  -f.y,  0),
			SIMD4<Float>(s.z,  u.z,  -f.z,  0),
			SIMD4<Float>(translation.x, translation.y, translation.z, 1)
		])
	}


	/// Returns an orthographic projection matrix (right-handed)
	///  Parameters:
	///   left: Left plane of the orthographic volume
	///   right: Right plane of the orthographic volume
	///   bottom: Bottom plane of the orthographic volume
	///   top: Top plane of the orthographic volume
	///   nearZ: Near plane distance
	///   farZ: Far plane distance
	///  Returns: Orthographic projection matrix as float4x4
	public static func orthographic(
		left: Float,
		right: Float,
		bottom: Float,
		top: Float,
		nearZ: Float,
		farZ: Float) -> float4x4
	{
		let rml = right - left
		let tmb = top - bottom
		let fmn = farZ - nearZ

		let tx = -(right + left) / rml
		let ty = -(top + bottom) / tmb
		let tz = -(farZ + nearZ) / fmn

		return float4x4([
			SIMD4<Float>(2 / rml,       0,         0, 0),
			SIMD4<Float>(0,       2 / tmb,         0, 0),
			SIMD4<Float>(0,             0,  -2 / fmn, 0),
			SIMD4<Float>(tx,           ty,        tz, 1)
		])
	}
	
	public static func float4x4_translation(_ t: SIMD3<Float>) -> simd_float4x4 {
		var matrix = matrix_identity_float4x4
		matrix.columns.3 = SIMD4<Float>(t.x, t.y, t.z, 1)
		return matrix
	}

	public static func float4x4_rotation(_ r: simd_quatf) -> simd_float4x4 {
		return simd_float4x4(r)
	}

	public static func float4x4_scaling(_ s: SIMD3<Float>) -> simd_float4x4 {
		var matrix = matrix_identity_float4x4
		matrix.columns.0.x = s.x
		matrix.columns.1.y = s.y
		matrix.columns.2.z = s.z
		return matrix
	}
}
