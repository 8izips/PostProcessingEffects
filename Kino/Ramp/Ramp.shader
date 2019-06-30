Shader "Hidden/PostProcessing/Ramp"
{
	HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);

	float4 _Color1;
	float4 _Color2;
	float2 _Direction;

#if _LINEAR
	float3 srgb_to_linear(float3 c)
	{
		return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
	}

	float3 linear_to_srgb(float3 c)
	{
		return max(1.055 * pow(c, 0.416666667) - 0.055, 0.0);
	}
#endif

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		float4 src = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
		float3 c_a = src.rgb;
		float3 grad1 = _Color1.rgb;
		float3 grad2 = _Color2.rgb;

		#if _LINEAR
		c_a = linear_to_srgb(c_a);
		grad1 = linear_to_srgb(grad1);
		grad2 = linear_to_srgb(grad2);
		#endif

		float param = dot(i.texcoord - 0.5, _Direction);
		float3 c_b = lerp(grad1, grad2, param + 0.5);

	#if _MULTIPLY
		float3 c_f = c_a * c_b;

	#elif _SCREEN
		float3 c_f = 1.0 - (1.0 - c_a) * (1.0 - c_b);

	#elif _SOFTLIGHT
		float3 c_u = c_a * c_b * 2.0 + (1.0 - c_b * 2.0) * c_a * c_a;
		float3 c_d = (1.0 - c_b) * c_a * 2.0 + (c_b * 2.0 - 1.0) * sqrt(c_a);
		float3 c_f = lerp(c_u, c_d, c_b > 0.5);

	#else
		float3 c_u = c_a * c_b * 2.0;
		float3 c_d = 1.0 - (1.0 - c_a) * (1.0 - c_b) * 2.0;

		#if _OVERLAY
			float3 c_f = lerp(c_u, c_d, c_a > 0.5);

		#else // _HARDLIGHT
			float3 c_f = lerp(c_u, c_d, c_b > 0.5);

		#endif
	#endif

	#if _LINEAR
		c_f = srgb_to_linear(c_f);
	#endif

		return float4(c_f, src.a);
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
			#pragma multi_compile _MULTIPLY _SCREEN _OVERLAY _HARDLIGHT _SOFTLIGHT
			#pragma multi_compile _ _LINEAR
			ENDHLSL
		}
	}
}