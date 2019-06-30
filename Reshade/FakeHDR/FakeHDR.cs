using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(FakeHDRRenderer), PostProcessEvent.AfterStack, "Custom/Reshade/FakeHDR")]
public sealed class FakeHDR : PostProcessEffectSettings
{
    [Range(0f, 8f), Tooltip("Power")]
    public FloatParameter power = new FloatParameter { value = 1.3f };

    [Range(0f, 8f), Tooltip("Radius 1")]
    public FloatParameter radius1 = new FloatParameter { value = 0.793f };

    [Range(0f, 8f), Tooltip("Raising this seems to make the effect stronger and also brighter.")]
    public FloatParameter radius2 = new FloatParameter { value = 0.87f };
}

public sealed class FakeHDRRenderer : PostProcessEffectRenderer<FakeHDR>
{
    static class ShaderPropertyID
    {
        internal static readonly int HDRPower = Shader.PropertyToID("_HDRPower");
        internal static readonly int Radius1 = Shader.PropertyToID("_Radius1");
        internal static readonly int Radius2 = Shader.PropertyToID("_Radius2");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/FakeHDR"));

        sheet.properties.SetFloat(ShaderPropertyID.HDRPower, settings.power);
        sheet.properties.SetFloat(ShaderPropertyID.Radius1, settings.radius1);
        sheet.properties.SetFloat(ShaderPropertyID.Radius2, settings.radius2);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
