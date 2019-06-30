Shader "Hidden/PostProcessing/DigitalGlitch"
{
	HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	TEXTURE2D_SAMPLER2D(_NoiseTex, sampler_NoiseTex);
	TEXTURE2D_SAMPLER2D(_TrashTex, sampler_TrashTex);

	float _Intensity;

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		float4 glitch = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.texcoord);

		float thresh = 1.001 - _Intensity * 1.001;
		float w_d = step(thresh, pow(glitch.z, 2.5));
		float w_f = step(thresh, pow(glitch.w, 2.5));
		float w_c = step(thresh, pow(glitch.z, 3.5));

		float2 uv = frac(i.texcoord + glitch.xy * w_d);
		float4 source = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
		float4 trash = SAMPLE_TEXTURE2D(_TrashTex, sampler_TrashTex, uv);
		float3 color = lerp(source, trash, w_f).rgb;
		float3 neg = saturate(color.grb + (1 - dot(color, 1)) * 0.5);
		color = lerp(color, neg, w_c);

		return float4(color, source.a);
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