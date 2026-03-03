using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace AuraConnect.Controls;

public sealed partial class AuraHeaderBar : UserControl
{
    private DispatcherTimer? _timer;
    private double _t;

    public static readonly DependencyProperty TitleProperty =
        DependencyProperty.Register(nameof(Title), typeof(string), typeof(AuraHeaderBar),
            new PropertyMetadata("", OnTitleChanged));

    public static readonly DependencyProperty SubtitleProperty =
        DependencyProperty.Register(nameof(Subtitle), typeof(string), typeof(AuraHeaderBar),
            new PropertyMetadata("", OnSubtitleChanged));

    public string Title
    {
        get => (string)GetValue(TitleProperty);
        set => SetValue(TitleProperty, value);
    }

    public string Subtitle
    {
        get => (string)GetValue(SubtitleProperty);
        set => SetValue(SubtitleProperty, value);
    }

    public AuraHeaderBar()
    {
        this.InitializeComponent();
        Loaded += OnLoaded;
        Unloaded += OnUnloaded;
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        TitleBlock.Text = Title.ToUpperInvariant();
        SubtitleBlock.Text = Subtitle;

        _timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(1000.0 / 30.0) };
        _timer.Tick += OnTick;
        _timer.Start();
    }

    private void OnUnloaded(object sender, RoutedEventArgs e)
    {
        _timer?.Stop();
        _timer = null;
    }

    private void OnTick(object? sender, object e)
    {
        _t += 1.0 / 30.0;
        var offset = Math.Sin(_t * 0.6) * 260;
        SweepContainer.RenderTransform = new Microsoft.UI.Xaml.Media.TranslateTransform { X = offset };
    }

    private static void OnTitleChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is AuraHeaderBar bar)
            bar.TitleBlock.Text = ((string)e.NewValue).ToUpperInvariant();
    }

    private static void OnSubtitleChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        if (d is AuraHeaderBar bar)
            bar.SubtitleBlock.Text = (string)e.NewValue;
    }
}
