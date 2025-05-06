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
		fovYRadians fov: Float,
		aspect: Float,
		nearZ n: Float,
		farZ f: Float) -> float4x4
	{
		let y = 1 / tan(fov * 0.5)      // cot(fov/2)
		let x = y / aspect
		let z = f / (f - n)             // maps z = near → 0, z = far → 1
		let wz = -(f * n) / (f - n)     // ‑near * far / (far‑near)

		return float4x4([
			SIMD4<Float>( x,  0,  0,  0),
			SIMD4<Float>( 0,  y,  0,  0),
			SIMD4<Float>( 0,  0,  z,  1),   // note:  [2][3] = +1
			SIMD4<Float>( 0,  0, wz,  0)
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
	/// Metal‑style RH orthographic (z 0…1)
	public static func orthographic(
		left l: Float,  right r: Float,
		bottom b: Float, top t: Float,
		nearZ n: Float,  farZ f: Float) -> float4x4
	{
		let rml = r - l
		let tmb = t - b
		let fmn = f - n

		return float4x4([
			SIMD4<Float>(       2 / rml,              0,        0, 0),
			SIMD4<Float>(             0,        2 / tmb,        0, 0),
			SIMD4<Float>(             0,              0,  1 / fmn, 0),   // z scale = 1/(far‑near)
			SIMD4<Float>(-(r + l) / rml, -(t + b) / tmb, -n / fmn, 1)
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
