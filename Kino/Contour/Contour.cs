using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(ContourRenderer), PostProcessEvent.BeforeStack, "Custom/Kino/Contour")]
public class Contour : PostProcessEffectSettings
{
    [Tooltip("Line Color")]
    public ColorParameter lineColor = new ColorParameter { value = Color.black };
    [Tooltip("Background Color")]
    public ColorParameter bgColor = new ColorParameter { value = new Color(1, 1, 1, 0) };
    [Range(0, 1), Tooltip("Lower Threshold")]
    public FloatParameter lowerThreshold = new FloatParameter { value = 0.05f };
    [Range(0, 1), Tooltip("Upper Threshold")]
    public FloatParameter upperThreshold = new FloatParameter { value = 0.5f };
    [Range(0, 1), Tooltip("Color Sensitivity")]
    public FloatParameter colorSensitivity = new FloatParameter { value = 0 };
    [Range(0, 1), Tooltip("Depth Sensitivity")]
    public FloatParameter depthSensitivity = new FloatParameter { value = 0.5f };
    [Range(0, 1), Tooltip("Normal Sensitivity")]
    public FloatParameter normalSensitivity = new FloatParameter { value = 0 };
    [Tooltip("Falloff Depth")]
    public FloatParameter falloffDepth = new FloatParameter { value = 40 };
}

public sealed class ContourRenderer : PostProcessEffectRenderer<Contour>
{
    static class ShaderPropertyID
    {
        internal static readonly int Color = Shader.PropertyToID("_Color");
        internal static readonly int Background = Shader.PropertyToID("_Background");
        internal static readonly int Threshold = Shader.PropertyToID("_Threshold");
        internal static readonly int InvRange = Shader.PropertyToID("_InvRange");
        internal static readonly int ColorSensitivity = Shader.PropertyToID("_ColorSensitivity");
        internal static readonly int DepthSensitivity = Shader.PropertyToID("_DepthSensitivity");
        internal static readonly int NormalSensitivity = Shader.PropertyToID("_NormalSensitivity");
        internal static readonly int InvFallOff = Shader.PropertyToID("_InvFallOff");
    }

    public override DepthTextureMode GetCameraFlags()
    {
        if (settings.normalSensitivity > 0)
            return DepthTextureMode.DepthNormals;
        if (settings.depthSensitivity > 0)
            return DepthTextureMode.Depth;

        return DepthTextureMode.None;
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Contour"));

        sheet.properties.SetColor(ShaderPropertyID.Color, settings.lineColor);
        sheet.properties.SetColor(ShaderPropertyID.Background, settings.bgColor);
        sheet.properties.SetFloat(ShaderPropertyID.Threshold, settings.lowerThreshold);
        sheet.properties.SetFloat(ShaderPropertyID.InvRange, 1 / (settings.upperThreshold - settings.lowerThreshold));
        sheet.properties.SetFloat(ShaderPropertyID.ColorSensitivity, settings.colorSensitivity);
        sheet.properties.SetFloat(ShaderPropertyID.DepthSensitivity, settings.depthSensitivity * 2);
        sheet.properties.SetFloat(ShaderPropertyID.NormalSensitivity, settings.normalSensitivity);
        sheet.properties.SetFloat(ShaderPropertyID.InvFallOff, 1 / settings.falloffDepth);

        if (settings.colorSensitivity > 0)
            sheet.EnableKeyword("_CONTOUR_COLOR");
        else
            sheet.DisableKeyword("_CONTOUR_COLOR");

        if (settings.depthSensitivity > 0)
            sheet.EnableKeyword("_CONTOUR_DEPTH");
        else
            sheet.DisableKeyword("_CONTOUR_DEPTH");

        if (settings.normalSensitivity > 0)
            sheet.EnableKeyword("_CONTOUR_NORMAL");
        else
            sheet.DisableKeyword("_CONTOUR_NORMAL");

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
