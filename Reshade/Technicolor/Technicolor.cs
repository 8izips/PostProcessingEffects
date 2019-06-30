using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(TechnicolorRenderer), PostProcessEvent.BeforeStack, "Custom/Reshade/Technicolor")]
public sealed class Technicolor : PostProcessEffectSettings
{
    [Tooltip("Higher means darker and more intense colors")]
    public ColorParameter colorStrength = new ColorParameter { value = new Color(0.2f, 0.2f, 0.2f) };
    [Range(0.5f, 1.5f), Tooltip("Higher means brighter image")]
    public FloatParameter brightness = new FloatParameter { value = 1f };
    [Range(0f, 1.5f), Tooltip("Additional saturation control since this effect tends to oversaturate the image")]
    public FloatParameter saturation = new FloatParameter { value = 1f };
    [Range(0f, 1f)]
    public FloatParameter strength = new FloatParameter { value = 1f };
}

public sealed class TechnicolorRenderer : PostProcessEffectRenderer<Technicolor>
{
    static class ShaderPropertyID
    {
        internal static readonly int ColorStrength = Shader.PropertyToID("_ColorStrength");
        internal static readonly int Brightness = Shader.PropertyToID("_Brightness");
        internal static readonly int Saturation = Shader.PropertyToID("_Saturation");
        internal static readonly int Strength = Shader.PropertyToID("_Strength");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Technicolor"));

        sheet.properties.SetColor(ShaderPropertyID.ColorStrength, settings.colorStrength);
        sheet.properties.SetFloat(ShaderPropertyID.Brightness, settings.brightness);
        sheet.properties.SetFloat(ShaderPropertyID.Saturation, settings.saturation);
        sheet.properties.SetFloat(ShaderPropertyID.Strength, settings.strength);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
