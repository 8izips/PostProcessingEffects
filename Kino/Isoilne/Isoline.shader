Shader "Hidden/PostProcessing/Isoline"
{
	HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Colors.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

	float4x4 _InverseView;

	float4 _LineColor;
	float4 _BackgroundColor;
	float4 _ContourAxis;
	float4 _ContourParams; // interval, scroll, width, source contribution
	float4 _ModParams; // strength, frequency, midpoint, offset

	struct VaryingsDepthSupport
	{
		float4 position : SV_Position;
		float2 texcoord : TEXCOORD0;
		float3 ray : TEXCOORD1;
	};

	float3 ComputeViewSpacePosition(VaryingsDepthSupport input)
	{
		// Render settings
		float near = _ProjectionParams.y;
		float far = _ProjectionParams.z;
		float isOrtho = unity_OrthoParams.w; // 0: perspective, 1: orthographic

		// Z buffer sample
		float z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, input.texcoord);

		// Far plane exclusion
//#if !defined(EXCLUDE_FAR_PLANE)
		//float mask = 1;
#if defined(UNITY_REVERSED_Z)
		float mask = z > 0;
#else
		float mask = z < 1;
#endif

		// Perspective: view space position = ray * depth
		float3 vposPers = input.ray * Linear01Depth(z);

		// Orthographic: linear depth (with reverse-Z support)
#if defined(UNITY_REVERSED_Z)
		float depthOrtho = -lerp(far, near, z);
#else
		float depthOrtho = -lerp(near, far, z);
#endif

		// Orthographic: view space position
		float3 vposOrtho = float3(input.ray.xy, depthOrtho);

		// Result: view space position
		return lerp(vposPers, vposOrtho, isOrtho) * mask;
	}

	float4x4 unity_CameraInvProjection;
	// Vertex shader that procedurally outputs a full screen triangle
	VaryingsDepthSupport VertexDepthSupport(uint vertexID : SV_VertexID)
	{
		// Render settings
		float far = _ProjectionParams.z;
		float2 orthoSize = unity_OrthoParams.xy;
		float isOrtho = unity_OrthoParams.w; // 0: perspective, 1: orthographic

		// Vertex ID -> clip space vertex position
		float x = (vertexID != 1) ? -1 : 3;
		float y = (vertexID == 2) ? -3 : 1;
		float3 vpos = float3(x, y, 1.0);

		// Perspective: view space vertex position of the far plane
		float3 rayPers = mul(unity_CameraInvProjection, vpos.xyzz * far).xyz;

		// Orthographic: view space vertex position
		float3 rayOrtho = float3(orthoSize * vpos.xy, 0);

		VaryingsDepthSupport o;
		o.position = float4(vpos.x, vpos.y, 1, 1);
		o.texcoord = (vpos.xy + 1) / 2;
		o.ray = lerp(rayPers, rayOrtho, isOrtho);
		return o;
	}

	float2 Contour(VaryingsDepthSupport input)
	{
		const float Width = _ContourParams.z;

		// Depth to world space conversion
		float3 vpos = ComputeViewSpacePosition(input);
		float3 wpos = mul(_InverseView, float4(vpos, 1)).xyz;

		// Potential value and derivatives
		float pot = (dot(_ContourAxis.xyz, wpos) + _ContourAxis.w) / _ContourParams.x;

		// Contour detection
		float fw = fwidth(pot);
		float fww = fw * Width;
		float ct = saturate((abs(1 - frac(pot) * 2) - 1 + fww) / fww);

		// Frequency filter
		ct = lerp(ct, 0, smoothstep(0.25, 0.5, fw));

		return float2(pot, ct);
	}

	float Modulation(float pot)
	{
		const float Strength = _ModParams.x;
		const float Frequency = _ModParams.y;
		const float Thresh = 1 - _ModParams.z;
		const float Midpoint = lerp(Thresh, 1, 0.95);
		const float Offset = _ModParams.w;

		float x = frac(pot * Frequency + Offset);
		float cv_in = smoothstep(Thresh, Midpoint, x);
		float cv_out = smoothstep(0, 1 - Midpoint, 1 - x);

		return lerp(1, cv_in * cv_out, Strength);
	}

	float3 BlendContour(half3 source, half contour)
	{
		const float SourceContrib = _ContourParams.w;

		float3 bg = lerp(source, _BackgroundColor.rgb, _BackgroundColor.a);
		float3 ln = _LineColor.rgb * lerp(1, Luminance(source), SourceContrib);

		return bg + ln * contour;
	}

	float4 FragmentIsoline(VaryingsDepthSupport input) : SV_Target
	{
		float2 contour = Contour(input);
		float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.texcoord);
		color.rgb = BlendContour(color.rgb, contour.y * Modulation(contour.x));
		return color;
	}

	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			HLSLPROGRAM
			#pragma vertex VertexDepthSupport
			#pragma fragment FragmentIsoline
			ENDHLSL
		}
	}
}