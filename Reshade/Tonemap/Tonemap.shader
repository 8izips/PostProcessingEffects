Shader "Hidden/PostProcessing/Tonemap"
{
    HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    float4 _MainTex_TexelSize;

    float _Gamma;
    float _Exposure;
    float _Saturation;
    float _Bleach;
	float _Defog;
	float4 _DefogColor;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).rgb;
		color = saturate(color - _Defog * _DefogColor * 2.55); // Defog
        color *= pow(2.0, _Exposure); // Exposure
        color = pow(abs(color), _Gamma); // Gamma

        const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
        float lum = dot(coefLuma, color);

        float L = saturate(10.0 * (lum - 0.45));
        float3 A2 = _Bleach * color;

        float3 result1 = 2.0f * color * lum;
        float3 result2 = 1.0f - 2.0f * (1.0f - lum) * (1.0f - color);

        float3 newColor = lerp(result1, result2, L);
        float3 mixRGB = A2 * newColor;
        color += ((1.0f - A2) * mixRGB);

        float3 middlegray = dot(color, (1.0 / 3.0));
        float3 diffcolor = color - middlegray;
        color = (color + diffcolor * _Saturation) / (1 + (diffcolor * _Saturation)); // Saturation

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
