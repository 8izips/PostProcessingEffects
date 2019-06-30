using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(CartoonRenderer), PostProcessEvent.AfterStack, "Custom/Reshade/Cartoon")]
public sealed class Cartoon : PostProcessEffectSettings
{
    [Range(0.1f, 10f), Tooltip("Amount of effect you want")]
    public FloatParameter power = new FloatParameter { value = 1.5f };
    [Range(0.1f, 6f), Tooltip("Edge Slope")]
    public FloatParameter edgeSlope = new FloatParameter { value = 1.5f };

}

public sealed class CartoonRenderer : PostProcessEffectRenderer<Cartoon>
{
    static class ShaderPropertyID
    {
        internal static readonly int Power = Shader.PropertyToID("_Power");
        internal static readonly int EdgeSlope = Shader.PropertyToID("_EdgeSlope");
    }

    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Cartoon"));

        sheet.properties.SetFloat(ShaderPropertyID.Power, settings.power);
        sheet.properties.SetFloat(ShaderPropertyID.EdgeSlope, settings.edgeSlope);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}
