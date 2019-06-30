using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(OilPaintRenderer), PostProcessEvent.AfterStack, "Custom/ShaderLab/OilPaint")]
public sealed class OilPaint : PostProcessEffectSettings
{
    [Range(0, 16), Tooltip("Brush Radius")]
    public IntParameter radius = new IntParameter { value = 1 };
}

public sealed class OilPaintRenderer : PostProcessEffectRenderer<OilPaint>
{
    static class ShaderPropertyID
    {
        internal static readonly int Radius = Shader.PropertyToID("_Radius");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/OilPaint"));
        sheet.properties.SetFloat(ShaderPropertyID.Radius, settings.radius);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
