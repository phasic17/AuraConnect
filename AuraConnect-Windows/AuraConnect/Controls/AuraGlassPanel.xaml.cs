using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace AuraConnect.Controls;

public sealed partial class AuraGlassPanel : UserControl
{
    public static readonly DependencyProperty InnerContentProperty =
        DependencyProperty.Register(nameof(InnerContent), typeof(object), typeof(AuraGlassPanel),
            new PropertyMetadata(null));

    public static readonly DependencyProperty GlowProperty =
        DependencyProperty.Register(nameof(Glow), typeof(bool), typeof(AuraGlassPanel),
            new PropertyMetadata(false, OnGlowChanged));

    public static readonly DependencyProperty CornerProperty =
        DependencyProperty.Register(nameof(Corner), typeof(double), typeof(AuraGlassPanel),
            new PropertyMetadata(18.0, OnCornerChanged));

    public object InnerContent
    {
        get => GetValue(InnerContentProperty);
        set => SetValue(InnerContentProperty, value);
    }

    public bool Glow
    {
        get => (bool)GetValue(GlowProperty);
        set => SetValue(GlowProperty, value);
    }

    public double Corner
    {
        get => (double)GetValue(CornerProperty);
        set => SetValue(CornerProperty, value);
    }

    public AuraGlassPanel()
    {
        this.InitializeComponent();
    }

    private static void OnGlowChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        // Glow via shadow could be added via Composition API
    }

    private static void OnCornerChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is AuraGlassPanel panel)
        {
            var cr = new Microsoft.UI.Xaml.CornerRadius((double)e.NewValue);
            panel.BackdropBorder.CornerRadius = cr;
            panel.GlowBorder.CornerRadius = cr;
        }
    }
}
