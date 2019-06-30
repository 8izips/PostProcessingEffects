Shader "Hidden/PostProcessing/FakeHDR"
{
    HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    float4 _MainTex_TexelSize;
    float _HDRPower;
    float _Radius1;
    float _Radius2;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).rgb;

        float3 bloom_sum1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(1.5, -1.5) * _Radius1 * _MainTex_TexelSize.x).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-1.5, -1.5) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(1.5, -1.5) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-1.5, 1.5) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.0, -2.5) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.0, 2.5) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-2.5, 0.0) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(2.5, 0.0) * _Radius1 * _MainTex_TexelSize.xy).rgb;
        bloom_sum1 *= 0.005;

        float3 bloom_sum2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(1.5, -1.5) * _Radius2 * _MainTex_TexelSize.x).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-1.5, -1.5) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(1.5, -1.5) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-1.5, 1.5) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.0, -2.5) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.0, 2.5) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(-2.5, 0.0) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(2.5, 0.0) * _Radius2 * _MainTex_TexelSize.xy).rgb;
        bloom_sum2 *= 0.010;

        float dist = _Radius2 - _Radius1;
        float3 hdr = (color + (bloom_sum2 - bloom_sum1)) * dist;
        float3 blend = hdr + color;
        color = saturate(pow(abs(blend), abs(_HDRPower)) + hdr);

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
