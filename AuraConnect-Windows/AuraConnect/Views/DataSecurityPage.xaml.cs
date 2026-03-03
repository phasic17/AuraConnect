using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.Models;
using AuraConnect.Theme;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class DataSecurityPage : Page
{
    private string? _selectedDeviceId;

    public DataSecurityPage()
    {
        this.InitializeComponent();
        BuildDeviceList();
    }

    private void BuildDeviceList()
    {
        var font = AuraTheme.OxaniumFont;

        foreach (var d in SecurityDevice.Samples)
        {
            var btn = new Button
            {
                Tag = d.Id,
                HorizontalAlignment = HorizontalAlignment.Stretch,
                HorizontalContentAlignment = HorizontalAlignment.Stretch,
                Background = new SolidColorBrush(Microsoft.UI.Colors.Transparent),
                BorderThickness = new Thickness(0),
                Padding = new Thickness(0, 8, 0, 8)
            };

            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var icon = new FontIcon
            {
                Glyph = d.KindIcon, FontSize = 14,
                Foreground = AuraTheme.WhiteBrush(0.70),
                Margin = new Thickness(0, 0, 12, 0),
                VerticalAlignment = VerticalAlignment.Center
            };
            Grid.SetColumn(icon, 0);

            var nameStack = new StackPanel { Spacing = 2 };
            nameStack.Children.Add(new TextBlock
            {
                Text = d.Name.ToUpperInvariant(),
                FontFamily = font, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                CharacterSpacing = 55, Foreground = AuraTheme.WhiteBrush(0.80)
            });
            nameStack.Children.Add(new TextBlock
            {
                Text = d.KindLabel,
                FontFamily = font, FontSize = 12,
                Foreground = AuraTheme.WhiteBrush(0.55)
            });
            Grid.SetColumn(nameStack, 1);

            grid.Children.Add(icon);
            grid.Children.Add(nameStack);

            btn.Content = grid;
            btn.Click += (s, e) => SelectDevice(d);
            DeviceListPanel.Children.Add(btn);
        }
    }

    private void SelectDevice(SecurityDevice device)
    {
        _selectedDeviceId = device.Id;
        LockDeviceButton.IsEnabled = true;
        BrickButton.IsEnabled = true;
        SelectedDeviceLabel.Text = $"Selected: {device.Name} \u2022 {device.KindLabel}";
    }
}
