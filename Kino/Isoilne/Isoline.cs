using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;


[Serializable]
[PostProcess(typeof(IsolineRenderer), PostProcessEvent.BeforeStack, "Custom/Kino/Isoline")]
public class Isoline : PostProcessEffectSettings
{
    // Contour Detection
    public Vector3Parameter baseAxis = new Vector3Parameter { value = Vector3.up };
    public FloatParameter lineInterval = new FloatParameter { value = 1 };
    public FloatParameter lineOffset = new FloatParameter { value = 0 };
    public FloatParameter lineScroll = new FloatParameter { value = 0 };

    // Line Style
    [ColorUsage(true, true)]
    public ColorParameter lineColor = new ColorParameter { value = new Color(1.5f, 0.2f, 0.2f, 1) };
    public FloatParameter lineWidth = new FloatParameter { value = 1.5f };
    [Range(0, 1)]
    public FloatParameter sourceContribution = new FloatParameter { value = 0 };
    public ColorParameter backgroundColor = new ColorParameter { value = new Color(0, 0, 0, 0) };

    // Color Modulation
    [Range(0, 1)]
    public FloatParameter modulationStrength = new FloatParameter { value = 0 };
    [Range(0, 1)]
    public FloatParameter modulationFrequency = new FloatParameter { value = 0.1f };
    [Range(0, 1)]
    public FloatParameter modulationWidth = new FloatParameter { value = 0.1f };
    public FloatParameter modulationOffset = new FloatParameter { value = 0 };
    public FloatParameter modulationScroll = new FloatParameter { value = 1 };
}

public sealed class IsolineRenderer : PostProcessEffectRenderer<Isoline>
{
    static class ShaderPropertyID
    {
        internal static readonly int InverseView = Shader.PropertyToID("_InverseView");
        internal static readonly int LineColor = Shader.PropertyToID("_LineColor");
        internal static readonly int BackgroundColor = Shader.PropertyToID("_BackgroundColor");
        internal static readonly int ContourAxis = Shader.PropertyToID("_ContourAxis");
        internal static readonly int ContourParams = Shader.PropertyToID("_ContourParams");
        internal static readonly int ModParams = Shader.PropertyToID("_ModParams");
    }

    public override DepthTextureMode GetCameraFlags()
    {
        return DepthTextureMode.Depth;
    }

    Vector4 MakeVector(Vector3 v, float w)
    {
        return new Vector4(v.x, v.y, v.z, w);
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Isoline"));

        sheet.properties.SetMatrix(ShaderPropertyID.InverseView, context.camera.cameraToWorldMatrix);
        sheet.properties.SetColor(ShaderPropertyID.LineColor, settings.lineColor);
        sheet.properties.SetColor(ShaderPropertyID.BackgroundColor, settings.backgroundColor);

        var offs = Time.time * settings.lineScroll + settings.lineOffset;
        sheet.properties.SetVector(ShaderPropertyID.ContourAxis, MakeVector(settings.baseAxis.value.normalized, -offs));
        sheet.properties.SetVector(ShaderPropertyID.ContourParams, new Vector4(settings.lineInterval, settings.lineScroll, settings.lineWidth, settings.sourceContribution));

        offs = Time.time * settings.modulationScroll + settings.modulationOffset;
        sheet.properties.SetVector(ShaderPropertyID.ModParams, new Vector4(settings.modulationStrength, settings.modulationFrequency, settings.modulationWidth, -offs));

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}