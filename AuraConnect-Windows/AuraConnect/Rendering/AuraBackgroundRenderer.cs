using System.Numerics;
using Microsoft.Graphics.Canvas;
using Microsoft.Graphics.Canvas.Brushes;
using Microsoft.Graphics.Canvas.Effects;
using Microsoft.Graphics.Canvas.UI.Xaml;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.UI;

namespace AuraConnect.Rendering;

/// <summary>
/// Port of AuraBackground.swift — Win2D CanvasAnimatedControl with dual-blob animation.
/// Energy: 0.0 = idle, 1.0 = connected, 2.0 = sending.
/// </summary>
public sealed class AuraBackgroundRenderer : UserControl
{
    private CanvasAnimatedControl? _canvas;
    private double _t;

    public static readonly DependencyProperty EnergyProperty =
        DependencyProperty.Register(nameof(Energy), typeof(double), typeof(AuraBackgroundRenderer),
            new PropertyMetadata(0.0));

    public double Energy
    {
        get => (double)GetValue(EnergyProperty);
        set => SetValue(EnergyProperty, value);
    }

    public AuraBackgroundRenderer()
    {
        _canvas = new CanvasAnimatedControl
        {
            TargetElapsedTime = TimeSpan.FromMilliseconds(1000.0 / 30.0), // 30 FPS
            ClearColor = Colors.Black,
            IsFixedTimeStep = true
        };
        _canvas.Draw += OnDraw;
        _canvas.Update += OnUpdate;
        Content = _canvas;
    }

    private void OnUpdate(ICanvasAnimatedControl sender, CanvasAnimatedUpdateEventArgs args)
    {
        _t += 1.0 / 30.0;
    }

    private void OnDraw(ICanvasAnimatedControl sender, CanvasAnimatedDrawEventArgs args)
    {
        var ds = args.DrawingSession;
        var size = sender.Size;
        var w = (float)size.Width;
        var h = (float)size.Height;

        if (w <= 0 || h <= 0) return;

        var e = Math.Clamp(Energy, 0.0, 2.0);

        // Energy mapping (matches Swift exactly)
        var drift = 0.10 + 0.06 * e;
        var blur = (float)(20 - 4 * e);
        var alphaA = 0.28 + 0.12 * e;
        var alphaB = 0.22 + 0.10 * e;
        var sweepOpacity = (float)(0.10 + 0.08 * e);
        var sweepSpeed = 0.35 + 0.25 * e;
        var sweepAmp = 160 + 120 * e;

        var a = 0.5 + 0.5 * Math.Sin(_t * (0.10 + 0.06 * e));
        var b = 0.5 + 0.5 * Math.Cos(_t * (0.07 + 0.05 * e));

        // Blob colors
        var cA = Color.FromArgb(255,
            (byte)(255 * (0.06 + 0.06 * a)),
            (byte)(255 * (0.30 + 0.55 * b)),
            255);
        var cB = Color.FromArgb(255,
            (byte)(255 * (0.04 + 0.05 * b)),
            (byte)(255 * (0.55 + 0.35 * a)),
            255);

        // Black base
        ds.Clear(Colors.Black);

        // Create offscreen layer for blobs to apply blur
        using var blobTarget = new CanvasRenderTarget(sender, size);
        using (var blobDs = blobTarget.CreateDrawingSession())
        {
            blobDs.Clear(Colors.Black);

            // Blob centers
            var c1 = new Vector2(
                (float)(w * (0.28 + drift * Math.Sin(_t * (0.28 + 0.10 * e)))),
                (float)(h * (0.36 + drift * Math.Cos(_t * (0.22 + 0.10 * e))))
            );
            var c2 = new Vector2(
                (float)(w * (0.74 + drift * Math.Cos(_t * (0.20 + 0.10 * e)))),
                (float)(h * (0.62 + drift * Math.Sin(_t * (0.26 + 0.12 * e))))
            );

            var maxDim = Math.Max(w, h);
            var r1 = (float)(maxDim * (0.66 + 0.06 * Math.Sin(_t * 0.18)));
            var r2 = (float)(maxDim * (0.84 + 0.06 * Math.Cos(_t * 0.16)));

            // Blob A
            DrawBlob(blobDs, sender, c1, r1, cA, (float)alphaA);
            // Blob B
            DrawBlob(blobDs, sender, c2, r2, cB, (float)alphaB);
        }

        // Apply Gaussian blur
        using var blurEffect = new GaussianBlurEffect
        {
            Source = blobTarget,
            BlurAmount = blur,
            BorderMode = EffectBorderMode.Soft
        };
        ds.DrawImage(blurEffect);

        // Sweep gradient overlay
        var sweepY = (float)(Math.Sin(_t * sweepSpeed) * sweepAmp);
        var auraBlue = Color.FromArgb((byte)(255 * sweepOpacity), 31, 158, 255);
        using var sweepBrush = new CanvasLinearGradientBrush(sender, new[]
        {
            new CanvasGradientStop { Position = 0f, Color = Colors.Transparent },
            new CanvasGradientStop { Position = 0.5f, Color = auraBlue },
            new CanvasGradientStop { Position = 1f, Color = Colors.Transparent }
        })
        {
            StartPoint = new Vector2(w * 0.5f, sweepY - h * 0.3f),
            EndPoint = new Vector2(w * 0.5f, sweepY + h * 0.3f)
        };
        ds.FillRectangle(0, 0, w, h, sweepBrush);

        // Noise overlay (subtle white)
        ds.FillRectangle(0, 0, w, h, Color.FromArgb(7, 255, 255, 255)); // 0.028 opacity

        // Vignette
        using var vignetteBrush = new CanvasRadialGradientBrush(sender, new[]
        {
            new CanvasGradientStop { Position = 0f, Color = Colors.Transparent },
            new CanvasGradientStop { Position = 0.1f, Color = Colors.Transparent },
            new CanvasGradientStop { Position = 1f, Color = Color.FromArgb(153, 0, 0, 0) } // 0.60
        })
        {
            Center = new Vector2(w / 2, h / 2),
            RadiusX = Math.Max(w, h) * 0.75f,
            RadiusY = Math.Max(w, h) * 0.75f
        };
        ds.FillRectangle(0, 0, w, h, vignetteBrush);
    }

    private static void DrawBlob(CanvasDrawingSession ds, ICanvasResourceCreator creator,
        Vector2 center, float radius, Color color, float alpha)
    {
        var innerColor = Color.FromArgb((byte)(255 * alpha), color.R, color.G, color.B);

        using var brush = new CanvasRadialGradientBrush(creator, new[]
        {
            new CanvasGradientStop { Position = 0f, Color = innerColor },
            new CanvasGradientStop { Position = 1f, Color = Colors.Transparent }
        })
        {
            Center = center,
            RadiusX = radius,
            RadiusY = radius
        };
        ds.FillEllipse(center, radius, radius, brush);

        // Rim highlight
        var rimColor = Color.FromArgb((byte)(255 * alpha * 0.45), color.R, color.G, color.B);
        using var rimBrush = new CanvasRadialGradientBrush(creator, new[]
        {
            new CanvasGradientStop { Position = 0f, Color = Colors.Transparent },
            new CanvasGradientStop { Position = 0.55f, Color = Colors.Transparent },
            new CanvasGradientStop { Position = 0.8f, Color = rimColor },
            new CanvasGradientStop { Position = 1f, Color = Colors.Transparent }
        })
        {
            Center = center,
            RadiusX = radius,
            RadiusY = radius
        };
        ds.FillEllipse(center, radius, radius, rimBrush);
    }
}
