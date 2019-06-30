using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(AdaptiveFogRenderer), PostProcessEvent.BeforeStack, "Custom/Reshade/AdaptiveFog")]
public sealed class AdaptiveFog : PostProcessEffectSettings
{
    [Tooltip("Color of the fog")]
    public ColorParameter fogColor = new ColorParameter { value = new Color(0.9f, 0.9f, 0.9f) };
    [Range(0f, 1f), Tooltip("The maximum fog factor. 1.0 makes distant objects completely fogged out, a lower factor will shimmer them through the fog")]
    public FloatParameter maxFogFactor = new FloatParameter { value = 0.5f };
    [Range(0f, 175f), Tooltip("The curve how quickly distant objects get fogged. A low value will make the fog appear just slightly. A high value will make the fog kick in rather quickly. The max value in the rage makes it very hard in general to view any objects outside fog")]
    public FloatParameter fogCurve = new FloatParameter { value = 1.5f };
    [Range(0f, 1f), Tooltip("Start of the fog. 0.0 is at the camera, 1.0 is at the horizon, 0.5 is halfway towards the horizon. Before this point no fog will appear")]
    public FloatParameter fogStart = new FloatParameter { value = 0.05f };
    [Range(0f, 50f), Tooltip("Threshold for what is a bright light (that causes bloom) and what isn't")]
    public FloatParameter bloomThreshold = new FloatParameter { value = 10.25f };
    [Range(0f, 100f), Tooltip("Strength of the bloom")]
    public FloatParameter bloomPower = new FloatParameter { value = 10.0f };
    [Range(0f, 1f), Tooltip("Width of the bloom")]
    public FloatParameter bloomWidth = new FloatParameter { value = 0.2f };
}

public sealed class AdaptiveFogRenderer : PostProcessEffectRenderer<AdaptiveFog>
{
    static class ShaderPropertyID
    {
        internal static readonly int FogColor = Shader.PropertyToID("_FogColor");
        internal static readonly int MaxFogFactor = Shader.PropertyToID("_MaxFogFactor");
        internal static readonly int FogCurve = Shader.PropertyToID("_FogCurve");
        internal static readonly int FogStart = Shader.PropertyToID("_FogStart");
        internal static readonly int BloomThreshold = Shader.PropertyToID("_BloomThreshold");
        internal static readonly int BloomPower = Shader.PropertyToID("_BloomPower");
        internal static readonly int BloomWidth = Shader.PropertyToID("_BloomWidth");
    }

    public override DepthTextureMode GetCameraFlags()
    {
        return DepthTextureMode.Depth;
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/AdaptiveFog"));

        sheet.properties.SetColor(ShaderPropertyID.FogColor, settings.fogColor);
        sheet.properties.SetFloat(ShaderPropertyID.MaxFogFactor, settings.maxFogFactor);
        sheet.properties.SetFloat(ShaderPropertyID.FogCurve, settings.fogCurve);
        sheet.properties.SetFloat(ShaderPropertyID.FogStart, settings.fogStart);
        sheet.properties.SetFloat(ShaderPropertyID.BloomThreshold, settings.bloomThreshold);
        sheet.properties.SetFloat(ShaderPropertyID.BloomPower, settings.bloomPower);
        sheet.properties.SetFloat(ShaderPropertyID.BloomWidth, settings.bloomWidth);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
