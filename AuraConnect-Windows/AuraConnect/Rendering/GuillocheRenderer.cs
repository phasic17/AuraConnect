using System.Numerics;
using Microsoft.Graphics.Canvas;
using Microsoft.Graphics.Canvas.UI.Xaml;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.UI;

namespace AuraConnect.Rendering;

/// <summary>
/// Port of AuraGuilloche.swift — concentric dial rings effect.
/// Uses Win2D CanvasControl (static, non-animated).
/// </summary>
public sealed class GuillocheRenderer : UserControl
{
    private CanvasControl? _canvas;

    public static readonly DependencyProperty RingCountProperty =
        DependencyProperty.Register(nameof(RingCount), typeof(int), typeof(GuillocheRenderer),
            new PropertyMetadata(52, OnPropertyChanged));

    public static readonly DependencyProperty RingOpacityProperty =
        DependencyProperty.Register(nameof(RingOpacity), typeof(double), typeof(GuillocheRenderer),
            new PropertyMetadata(0.13, OnPropertyChanged));

    public static readonly DependencyProperty RingLineWidthProperty =
        DependencyProperty.Register(nameof(RingLineWidth), typeof(double), typeof(GuillocheRenderer),
            new PropertyMetadata(0.7, OnPropertyChanged));

    public int RingCount
    {
        get => (int)GetValue(RingCountProperty);
        set => SetValue(RingCountProperty, value);
    }

    public double RingOpacity
    {
        get => (double)GetValue(RingOpacityProperty);
        set => SetValue(RingOpacityProperty, value);
    }

    public double RingLineWidth
    {
        get => (double)GetValue(RingLineWidthProperty);
        set => SetValue(RingLineWidthProperty, value);
    }

    public GuillocheRenderer()
    {
        _canvas = new CanvasControl();
        _canvas.Draw += OnDraw;
        Content = _canvas;
        IsHitTestVisible = false;
    }

    private static void OnPropertyChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is GuillocheRenderer r) r._canvas?.Invalidate();
    }

    private void OnDraw(CanvasControl sender, CanvasDrawEventArgs args)
    {
        var ds = args.DrawingSession;
        var w = (float)sender.ActualWidth;
        var h = (float)sender.ActualHeight;

        if (w <= 0 || h <= 0) return;

        var center = new Vector2(w / 2, h / 2);
        var maxR = Math.Min(w, h) * 0.78f;
        var step = maxR / RingCount;
        var lineW = (float)RingLineWidth;

        for (int i = 0; i < RingCount; i++)
        {
            var r = (i + 1) * step;
            var alpha = (float)(RingOpacity * (i % 2 == 0 ? 1.0 : 0.55));

            // Highlight ring (white)
            var highlightColor = Color.FromArgb((byte)(255 * alpha), 255, 255, 255);
            ds.DrawEllipse(center, r, r, highlightColor, lineW);

            // Shadow ring (black, slightly offset)
            var shadowColor = Color.FromArgb((byte)(255 * alpha * 0.75), 0, 0, 0);
            ds.DrawEllipse(new Vector2(center.X + 0.6f, center.Y + 0.8f), r, r, shadowColor, lineW);
        }
    }
}
