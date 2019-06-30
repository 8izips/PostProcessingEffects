Shader "Hidden/PostProcessing/Technicolor"
{
    HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    float4 _MainTex_TexelSize;

	float4 _ColorStrength;
    float _Brightness;
	float _Saturation;
    float _Strength;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).rgb;

		float3 temp = 1.0 - color;
		float3 target = temp.grg;
		float3 target2 = temp.bbr;
		float3 temp2 = color * target;
		temp2 *= target2;

		temp = temp2 * _ColorStrength;
		temp2 *= _Brightness;

		target = temp.grg;
		target2 = temp.bbr;

		temp = color - target;
		temp += temp2;
		temp2 = temp - target2;

		color = lerp(color, temp2, _Strength);
		color = lerp(dot(color, 0.333), color, _Saturation);

        return float4(color, 1.0);
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
