using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(StreakRenderer), PostProcessEvent.BeforeStack, "Custom/Kino/Streak")]
public sealed class Streak : PostProcessEffectSettings
{
    [Range(0, 5)] public FloatParameter threshold = new FloatParameter { value = 0.75f };
    [Range(0, 1)] public FloatParameter stretch = new FloatParameter { value = 0.5f };
    [Range(0, 1)] public FloatParameter intensity = new FloatParameter { value = 0.25f };
    [ColorUsage(false)] public ColorParameter tint = new ColorParameter { value = new Color(0.55f, 0.55f, 1) };
}

public sealed class StreakRenderer : PostProcessEffectRenderer<Streak>
{
    static class ShaderPropertyID
    {
        internal static readonly int Threshold = Shader.PropertyToID("_Threshold");
        internal static readonly int Stretch = Shader.PropertyToID("_Stretch");
        internal static readonly int Intensity = Shader.PropertyToID("_Intensity");
        internal static readonly int Color = Shader.PropertyToID("_Color");
        internal static readonly int HighTex = Shader.PropertyToID("_HighTex");
    }

    const int MaxMipLevel = 16;
    int[] _mipWidth;
    int[] _rtMipDown;
    int[] _rtMipUp;
    public override void Init()
    {
        _mipWidth = new int[MaxMipLevel];
        _rtMipDown = new int[MaxMipLevel];
        _rtMipUp = new int[MaxMipLevel];

        for (var i = 0; i < MaxMipLevel; i++) {
            _rtMipDown[i] = Shader.PropertyToID("_MipDown" + i);
            _rtMipUp[i] = Shader.PropertyToID("_MipUp" + i);
        }
    }

    public override void Render(PostProcessRenderContext context)
    {
        var cmd = context.command;
        cmd.BeginSample("Streak");

        // Shader uniforms
        var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/Streak"));
        sheet.properties.SetFloat(ShaderPropertyID.Threshold, settings.threshold);
        sheet.properties.SetFloat(ShaderPropertyID.Stretch, settings.stretch);
        sheet.properties.SetFloat(ShaderPropertyID.Intensity, settings.intensity);
        sheet.properties.SetColor(ShaderPropertyID.Color, settings.tint);

        // Calculate the mip widths.
        _mipWidth[0] = context.screenWidth;
        for (var i = 1; i < MaxMipLevel; i++)
            _mipWidth[i] = _mipWidth[i - 1] / 2;

        // Apply the prefilter and store into MIP 0.
        var height = context.screenHeight / 2;
        context.GetScreenSpaceTemporaryRT(
            cmd, _rtMipDown[0], 0,
            RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Default,
            FilterMode.Bilinear, _mipWidth[0], height
        );
        cmd.BlitFullscreenTriangle(context.source, _rtMipDown[0], sheet, 0);

        // Build the MIP pyramid.
        var level = 1;
        for (; level < MaxMipLevel && _mipWidth[level] > 7; level++) {
            context.GetScreenSpaceTemporaryRT(
                cmd, _rtMipDown[level], 0,
                RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Default,
                FilterMode.Bilinear, _mipWidth[level], height
            );
            cmd.BlitFullscreenTriangle(_rtMipDown[level - 1], _rtMipDown[level], sheet, 1);
        }

        // MIP 0 is not needed at this point.
        cmd.ReleaseTemporaryRT(_rtMipDown[level]);

        // Upsample and combine.
        var lastRT = _rtMipDown[--level];
        for (level--; level >= 1; level--) {
            context.GetScreenSpaceTemporaryRT(
                cmd, _rtMipUp[level], 0,
                RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Default,
                FilterMode.Bilinear, _mipWidth[level], height
            );
            cmd.SetGlobalTexture(ShaderPropertyID.HighTex, _rtMipDown[level]);
            cmd.BlitFullscreenTriangle(lastRT, _rtMipUp[level], sheet, 2);

            cmd.ReleaseTemporaryRT(_rtMipDown[level]);
            cmd.ReleaseTemporaryRT(lastRT);

            lastRT = _rtMipUp[level];
        }

        // Final composition.
        cmd.SetGlobalTexture(ShaderPropertyID.HighTex, context.source);
        cmd.BlitFullscreenTriangle(lastRT, context.destination, sheet, 3);

        // Cleaning up.
        cmd.ReleaseTemporaryRT(lastRT);
        cmd.EndSample("Streak");
    }
}