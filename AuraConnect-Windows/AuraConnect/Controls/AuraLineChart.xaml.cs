using System.Numerics;
using Microsoft.Graphics.Canvas;
using Microsoft.Graphics.Canvas.Geometry;
using Microsoft.Graphics.Canvas.Effects;
using Microsoft.Graphics.Canvas.UI.Xaml;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.UI;

namespace AuraConnect.Controls;

/// <summary>
/// Port of AuraLineChart from LedgerUsageView.swift — Win2D line chart with gradient glow.
/// </summary>
public sealed partial class AuraLineChart : UserControl
{
    private static readonly Color AuraBlue = Color.FromArgb(255, 31, 158, 255);

    public static readonly DependencyProperty ValuesProperty =
        DependencyProperty.Register(nameof(Values), typeof(double[]), typeof(AuraLineChart),
            new PropertyMetadata(Array.Empty<double>(), OnValuesChanged));

    public double[] Values
    {
        get => (double[])GetValue(ValuesProperty);
        set => SetValue(ValuesProperty, value);
    }

    public AuraLineChart()
    {
        this.InitializeComponent();
    }

    private static void OnValuesChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is AuraLineChart chart) chart.ChartCanvas.Invalidate();
    }

    private void OnDraw(CanvasControl sender, CanvasDrawEventArgs args)
    {
        var ds = args.DrawingSession;
        var w = (float)sender.ActualWidth;
        var h = (float)sender.ActualHeight;
        var values = Values;

        if (w <= 0 || h <= 0 || values is null || values.Length == 0) return;

        var maxV = values.Max();
        var minV = values.Min();
        if (Math.Abs(maxV - minV) < 1e-9) maxV = minV + 1;

        float X(int i) => values.Length > 1 ? i * (w / (values.Length - 1)) : 0;
        float Y(double v) => h - (float)((v - minV) / (maxV - minV)) * (h - 8) - 4;

        // Grid lines
        for (int g = 0; g < 4; g++)
        {
            float gy = g * (h / 3);
            ds.DrawLine(0, gy, w, gy, Color.FromArgb(15, 255, 255, 255), 1);
        }

        // Build path
        using var pathBuilder = new CanvasPathBuilder(sender);
        pathBuilder.BeginFigure(X(0), Y(values[0]));
        for (int i = 1; i < values.Length; i++)
            pathBuilder.AddLine(X(i), Y(values[i]));
        pathBuilder.EndFigure(CanvasFigureLoop.Open);
        using var geometry = CanvasGeometry.CreatePath(pathBuilder);

        // Glow (thick, blurred)
        using var glowTarget = new CanvasRenderTarget(sender, sender.Size);
        using (var glowDs = glowTarget.CreateDrawingSession())
        {
            glowDs.Clear(Microsoft.UI.Colors.Transparent);
            glowDs.DrawGeometry(geometry, Color.FromArgb(51, AuraBlue.R, AuraBlue.G, AuraBlue.B), 8); // 0.20 opacity
        }
        using var blurEffect = new GaussianBlurEffect { Source = glowTarget, BlurAmount = 6 };
        ds.DrawImage(blurEffect);

        // Main line
        ds.DrawGeometry(geometry, Color.FromArgb(191, AuraBlue.R, AuraBlue.G, AuraBlue.B), 2); // 0.75 opacity

        // Points
        for (int i = 0; i < values.Length; i++)
        {
            ds.FillCircle(X(i), Y(values[i]), 2.5f, Color.FromArgb(217, 255, 255, 255)); // 0.85 opacity
        }
    }
}
