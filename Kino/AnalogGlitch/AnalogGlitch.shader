Shader "Hidden/PostProcessing/AnalogGlitch"
{
	HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);

	float2 _ScanLineJitter; // (displacement, threshold)
	float2 _VerticalJump;   // (amount, time)
	float _HorizontalShake;
	float2 _ColorDrift;     // (amount, time)

	float nrand(float x, float y)
	{
		return frac(sin(dot(float2(x, y), float2(12.9898, 78.233))) * 43758.5453);
	}

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		float u = i.texcoord.x;
		float v = i.texcoord.y;

		// Scan line jitter
		float jitter = nrand(v, _Time.x) * 2 - 1;
		jitter *= step(_ScanLineJitter.y, abs(jitter)) * _ScanLineJitter.x;

		// Vertical jump
		float jump = lerp(v, frac(v + _VerticalJump.y), _VerticalJump.x);

		// Horizontal shake
		float shake = (nrand(_Time.x, 2) - 0.5) * _HorizontalShake;

		// Color drift
		float drift = sin(jump + _ColorDrift.y) * _ColorDrift.x;

		float4 src1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(float2(u + jitter + shake, jump)));
		float4 src2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, frac(float2(u + jitter + shake + drift, jump)));

		return float4(src1.r, src2.g, src1.b, 1);
	}

	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			HLSLPROGRAM
			#pragma vertex VertDefault
			#pragma fragment Frag
			ENDHLSL
		}
	}
}