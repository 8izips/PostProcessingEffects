using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(GrayscaleRenderer), PostProcessEvent.AfterStack, "Custom/Grayscale")]
public sealed class Grayscale : PostProcessEffectSettings
{
    [Range(0f, 1f), Tooltip("Grayscale effect intensity.")]
    public FloatParameter blend = new FloatParameter { value = 0.5f };
}

public sealed class GrayscaleRenderer : PostProcessEffectRenderer<Grayscale>
{
    static class ShaderPropertyID
    {
        internal static readonly int Blend = Shader.PropertyToID("_Blend");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Grayscale"));

        sheet.properties.SetFloat(ShaderPropertyID.Blend, settings.blend);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}