using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(TonemapRenderer), PostProcessEvent.AfterStack, "Custom/Reshade/Tonemap")]
public sealed class Tonemap : PostProcessEffectSettings
{
    [Range(0f, 2f), Tooltip("Adjust midtones. 1.000 is neutral. ")]
    public FloatParameter gamma = new FloatParameter { value = 1.0f };
    [Range(-1f, 1f), Tooltip("Adjust exposure")]
    public FloatParameter exposure = new FloatParameter { value = 0.0f };
    [Range(-1f, 1f), Tooltip("Adjust saturation")]
    public FloatParameter saturation = new FloatParameter { value = 0.0f };
    [Range(0f, 1f), Tooltip("Brightens the shadows and fades the colors")]
    public FloatParameter bleach = new FloatParameter { value = 0.0f };
    [Range(0f, 1f), Tooltip("How much of the color tint to remove")]
    public FloatParameter defog = new FloatParameter { value = 0.0f };
    [ColorUsage(false), Tooltip("Defog Color")]
    public ColorParameter defogColor = new ColorParameter { value = Color.blue };
}

public sealed class TonemapRenderer : PostProcessEffectRenderer<Tonemap>
{
    static class ShaderPropertyID
    {
        internal static readonly int Gamma = Shader.PropertyToID("_Gamma");
        internal static readonly int Exposure = Shader.PropertyToID("_Exposure");
        internal static readonly int Saturation = Shader.PropertyToID("_Saturation");
        internal static readonly int Bleach = Shader.PropertyToID("_Bleach");
        internal static readonly int Defog = Shader.PropertyToID("_Defog");
        internal static readonly int DefogColor = Shader.PropertyToID("_DefogColor");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Tonemap"));

        sheet.properties.SetFloat(ShaderPropertyID.Gamma, settings.gamma);
        sheet.properties.SetFloat(ShaderPropertyID.Exposure, settings.exposure);
        sheet.properties.SetFloat(ShaderPropertyID.Saturation, settings.saturation);
        sheet.properties.SetFloat(ShaderPropertyID.Bleach, settings.bleach);
        sheet.properties.SetFloat(ShaderPropertyID.Defog, settings.defog);
        sheet.properties.SetColor(ShaderPropertyID.DefogColor, settings.defogColor);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
