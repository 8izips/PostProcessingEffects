Shader "Hidden/PostProcessing/Cartoon"
{
    HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    float4 _MainTex_TexelSize;

    float _Power;
    float _EdgeSlope;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).rgb;

        float3 CoefLuma2 = float3(0.2126, 0.7152, 0.0722);  //Values to calculate luma with

        float3 color1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + _MainTex_TexelSize.xy).rgb;
        float diff1 = dot(CoefLuma2, color1);
        float3 color2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord - _MainTex_TexelSize.xy).rgb;
        diff1 = dot(float4(CoefLuma2, -1.0), float4(color2, diff1));

        float3 color3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(_MainTex_TexelSize.x, -_MainTex_TexelSize.y)).rgb;
        float diff2 = dot(CoefLuma2, color3);
        float3 color4 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-_MainTex_TexelSize.x, _MainTex_TexelSize.y)).rgb;
        diff2 = dot(float4(CoefLuma2, -1.0), float4(color4, diff2));

        float edge = dot(float2(diff1, diff2), float2(diff1, diff2));
        color -= pow(abs(edge), _EdgeSlope) * _Power;

        return saturate(float4(color, 1.0));
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
