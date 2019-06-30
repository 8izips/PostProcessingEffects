using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(AnalogGlitchRenderer), PostProcessEvent.BeforeStack, "Custom/Kino/AnalogGlitch")]
public class AnalogGlitch : PostProcessEffectSettings
{
    [Range(0, 1), Tooltip("Scan line jitter")]
    public FloatParameter scanLineJitter = new FloatParameter { value = 0 };

    [Range(0, 1), Tooltip("Vertical jump")]
    public FloatParameter verticalJump = new FloatParameter { value = 0 };

    [Range(0, 1), Tooltip("Vertical jump")]
    public FloatParameter horizontalShake = new FloatParameter { value = 0 };

    [Range(0, 1), Tooltip("Color Drift")]
    public FloatParameter colorDrift = new FloatParameter { value = 0 };
}

public sealed class AnalogGlitchRenderer : PostProcessEffectRenderer<AnalogGlitch>
{
    static class ShaderPropertyID
    {
        internal static readonly int ScanLineJitter = Shader.PropertyToID("_ScanLineJitter");
        internal static readonly int VerticalJump = Shader.PropertyToID("_VerticalJump");
        internal static readonly int HorizontalShake = Shader.PropertyToID("_HorizontalShake");
        internal static readonly int ColorDrift = Shader.PropertyToID("_ColorDrift");
    }

    float verticalJumpTime;
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/AnalogGlitch"));

        verticalJumpTime += Time.deltaTime * settings.verticalJump * 11.3f;

        var sl_thresh = Mathf.Clamp01(1.0f - settings.scanLineJitter * 1.2f);
        var sl_disp = 0.002f + Mathf.Pow(settings.scanLineJitter, 3) * 0.05f;
        var vj = new Vector2(settings.verticalJump, verticalJumpTime);
        var cd = new Vector2(settings.colorDrift * 0.04f, Time.time * 606.11f);

        sheet.properties.SetVector(ShaderPropertyID.ScanLineJitter, new Vector2(sl_disp, sl_thresh));
        sheet.properties.SetVector(ShaderPropertyID.VerticalJump, vj);
        sheet.properties.SetFloat(ShaderPropertyID.HorizontalShake, settings.horizontalShake * 0.2f);
        sheet.properties.SetVector(ShaderPropertyID.ColorDrift, cd);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
