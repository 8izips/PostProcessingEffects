using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(PencilRenderer), PostProcessEvent.AfterStack, "Custom/ShaderLab/Pencil")]
public sealed class Pencil : PostProcessEffectSettings
{
    [Range(0.00001f, 0.01f), Tooltip("Gradient Threshold")]
    public FloatParameter gradThreshold = new FloatParameter { value = 0.01f };
    [Range(0f, 1f), Tooltip("Color Threshold")]
    public FloatParameter colorThreshold = new FloatParameter { value = 0.5f };
    [Range(0f, 100f)]
    public FloatParameter sensivity = new FloatParameter { value = 10f };
}

public sealed class PencilRenderer : PostProcessEffectRenderer<Pencil>
{
    static class ShaderPropertyID
    {
        internal static readonly int GradThreshold = Shader.PropertyToID("_GradThreshold");
        internal static readonly int ColorThreshold = Shader.PropertyToID("_ColorThreshold");
        internal static readonly int Sensivity = Shader.PropertyToID("_Sensivity");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Pencil"));

        sheet.properties.SetFloat(ShaderPropertyID.GradThreshold, settings.gradThreshold);
        sheet.properties.SetFloat(ShaderPropertyID.ColorThreshold, settings.colorThreshold);
        sheet.properties.SetFloat(ShaderPropertyID.Sensivity, settings.sensivity);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
