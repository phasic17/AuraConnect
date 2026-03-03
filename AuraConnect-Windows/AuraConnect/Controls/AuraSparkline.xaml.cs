using System.Numerics;
using Microsoft.Graphics.Canvas.Geometry;
using Microsoft.Graphics.Canvas.UI.Xaml;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.UI;

namespace AuraConnect.Controls;

/// <summary>
/// Port of AuraSparkline from LedgerUsageView.swift — minimal line chart (no labels).
/// </summary>
public sealed partial class AuraSparkline : UserControl
{
    public static readonly DependencyProperty ValuesProperty =
        DependencyProperty.Register(nameof(Values), typeof(double[]), typeof(AuraSparkline),
            new PropertyMetadata(Array.Empty<double>(), OnValuesChanged));

    public double[] Values
    {
        get => (double[])GetValue(ValuesProperty);
        set => SetValue(ValuesProperty, value);
    }

    public AuraSparkline()
    {
        this.InitializeComponent();
    }

    private static void OnValuesChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is AuraSparkline sparkline) sparkline.SparkCanvas.Invalidate();
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
        float Y(double v) => h - (float)((v - minV) / (maxV - minV)) * (h - 4) - 2;

        using var pathBuilder = new CanvasPathBuilder(sender);
        pathBuilder.BeginFigure(X(0), Y(values[0]));
        for (int i = 1; i < values.Length; i++)
            pathBuilder.AddLine(X(i), Y(values[i]));
        pathBuilder.EndFigure(CanvasFigureLoop.Open);
        using var geometry = CanvasGeometry.CreatePath(pathBuilder);

        ds.DrawGeometry(geometry, Color.FromArgb(140, 255, 255, 255), 1.5f); // white @ 0.55
    }
}
