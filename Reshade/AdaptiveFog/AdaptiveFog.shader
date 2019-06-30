Shader "Hidden/PostProcessing/AdaptiveFog"
{
    HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

    TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
    float4 _MainTex_TexelSize;
	TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);

	float _BloomThreshold;
	float _BloomPower;
	float _BloomWidth;
	float4 _FogColor;
	float _MaxFogFactor;
	float _FogCurve;
	float _FogStart;

    float4 Frag(VaryingsDefault i) : SV_Target
    {
        float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
		float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.texcoord).r);

		float3 blurColor2 = 0;
		float3 blurtemp = 0;
		float maxDistance = 8 * _BloomWidth;
		float curDistance = 0;
		float sampleCount = 25.0;
		float2 blurtempvalue = i.texcoord * _MainTex_TexelSize * _BloomWidth;
		float2 bloomSample = float2(2.5, -2.5);
		float2 bloomSampleValue;

		for (bloomSample.x = (2.5); bloomSample.x > -2.0; bloomSample.x = bloomSample.x - 1.0)
		{
			bloomSampleValue.x = bloomSample.x * blurtempvalue.x;
			float2 distancetemp = bloomSample.x * bloomSample.x * _BloomWidth;

			for (bloomSample.y = (-2.5); bloomSample.y < 2.0; bloomSample.y = bloomSample.y + 1.0)
			{
				distancetemp.y = bloomSample.y * bloomSample.y;
				curDistance = (distancetemp.y * _BloomWidth) + distancetemp.x;
				bloomSampleValue.y = bloomSample.y * blurtempvalue.y;
				blurtemp = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + bloomSampleValue).rgb;
				blurColor2.rgb += lerp(blurtemp.rgb, color.rgb, sqrt(curDistance / maxDistance));
			}
		}
		blurColor2.rgb = (blurColor2.rgb / (sampleCount - (_BloomPower - _BloomThreshold * 5)));

		float bloomAmount = (dot(color.rgb, float3(0.299f, 0.587f, 0.114f)));
		float4 blurColor = float4(blurColor2.rgb * (_BloomPower + 4.0), 1.0);
		blurColor = saturate(lerp(color, blurColor, bloomAmount));

		float fogFactor = clamp(saturate(depth - _FogStart) * _FogCurve, 0.0, _MaxFogFactor);

		return lerp(color, lerp(blurColor, _FogColor, fogFactor), fogFactor);
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
