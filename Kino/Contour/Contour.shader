Shader "Hidden/PostProcessing/Contour"
{
	HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	float4 _MainTex_TexelSize;
	TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
	TEXTURE2D_SAMPLER2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2);

	float4 _Color;
	float4 _Background;

	float _Threshold;
	float _InvRange;

	float _ColorSensitivity;
	float _DepthSensitivity;
	float _NormalSensitivity;
	float _InvFallOff;

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		// Source color
		float4 c0 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

		// Four sample points of the roberts cross operator
		float2 uv0 = i.texcoord;                                   // TL
		float2 uv1 = i.texcoord + _MainTex_TexelSize.xy;           // BR
		float2 uv2 = i.texcoord + float2(_MainTex_TexelSize.x, 0); // TR
		float2 uv3 = i.texcoord + float2(0, _MainTex_TexelSize.y); // BL

		float edge = 0;

	#ifdef _CONTOUR_COLOR
		// Color samples
		float3 c1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv1).rgb;
		float3 c2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv2).rgb;
		float3 c3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv3).rgb;

		// Roberts cross operator
		float3 cg1 = c1 - c0;
		float3 cg2 = c3 - c2;
		float cg = sqrt(dot(cg1, cg1) + dot(cg2, cg2));

		edge = cg * _ColorSensitivity;
	#endif

	#ifdef _CONTOUR_DEPTH
		// Depth samples
		float zs0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv0);
		float zs1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv1);
		float zs2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv2);
		float zs3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv3);

		// Calculate fall-off parameter from the depth of the nearest point
		float zm = min(min(min(zs0, zs1), zs2), zs3);
		float falloff = 1.0 - saturate(LinearEyeDepth(zm) * _InvFallOff);

		// Convert to linear depth values.
		float z0 = Linear01Depth(zs0);
		float z1 = Linear01Depth(zs1);
		float z2 = Linear01Depth(zs2);
		float z3 = Linear01Depth(zs3);

		// Roberts cross operator
		float zg1 = z1 - z0;
		float zg2 = z3 - z2;
		float zg = sqrt(zg1 * zg1 + zg2 * zg2);

		edge = max(edge, zg * falloff * _DepthSensitivity / Linear01Depth(zm));
	#endif

	#ifdef _CONTOUR_NORMAL
		// Normal samples from the G-buffer
		float3 n0 = SAMPLE_TEXTURE2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2, uv0).rgb;
		float3 n1 = SAMPLE_TEXTURE2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2, uv1).rgb;
		float3 n2 = SAMPLE_TEXTURE2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2, uv2).rgb;
		float3 n3 = SAMPLE_TEXTURE2D(_CameraGBufferTexture2, sampler_CameraGBufferTexture2, uv3).rgb;

		// Roberts cross operator
		float3 ng1 = n1 - n0;
		float3 ng2 = n3 - n2;
		float ng = sqrt(dot(ng1, ng1) + dot(ng2, ng2));

		edge = max(edge, ng * _NormalSensitivity);
	#endif

		// Thresholding
		edge = saturate((edge - _Threshold) * _InvRange);

		float3 cb = lerp(c0.rgb, _Background.rgb, _Background.a);
		float3 co = lerp(cb, _Color.rgb, edge * _Color.a);
		return float4(co, c0.a);
	}

	ENDHLSL

	SubShader
	{
		ZTest Always Cull Off ZWrite Off

		Pass
		{
			HLSLPROGRAM
			#pragma vertex VertDefault
			#pragma fragment Frag
			#pragma multi_compile _ _CONTOUR_COLOR
			#pragma multi_compile _ _CONTOUR_DEPTH
			#pragma multi_compile _ _CONTOUR_NORMAL
			ENDHLSL
		}
	}
}
