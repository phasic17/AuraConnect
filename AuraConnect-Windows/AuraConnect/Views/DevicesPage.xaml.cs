using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.Models;
using AuraConnect.Services;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class DevicesPage : Page
{
    private readonly BluetoothService _bt = App.Bluetooth;

    public DevicesPage()
    {
        this.InitializeComponent();
        _bt.DevicesChanged += RefreshDeviceList;
        _bt.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(BluetoothService.IsScanning))
                StopButton.IsEnabled = _bt.IsScanning;
        };
    }

    private void OnScanClick(object sender, RoutedEventArgs e) => _bt.StartScan();
    private void OnStopClick(object sender, RoutedEventArgs e) => _bt.StopScan();

    private void RefreshDeviceList()
    {
        DeviceListPanel.Children.Clear();

        if (_bt.Devices.Count == 0)
        {
            DeviceListPanel.Children.Add(new TextBlock
            {
                Text = "NO DEVICES FOUND. PUT THE PUCK INTO TRANSFER MODE AND SCAN.",
                FontFamily = new FontFamily("ms-appx:///Assets/Fonts/Oxanium-VariableFont_wght.ttf#Oxanium"),
                FontSize = 12,
                CharacterSpacing = 40,
                Foreground = new SolidColorBrush(Color.FromArgb(166, 255, 255, 255))
            });
            return;
        }

        foreach (var device in _bt.Devices)
        {
            DeviceListPanel.Children.Add(CreateDeviceCard(device));
        }
    }

    private static UIElement CreateDeviceCard(AuraDevice device)
    {
        var font = new FontFamily("ms-appx:///Assets/Fonts/Oxanium-VariableFont_wght.ttf#Oxanium");

        var nameBlock = new TextBlock
        {
            Text = device.Name.ToUpperInvariant(),
            FontFamily = font, FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            CharacterSpacing = 40, Foreground = new SolidColorBrush(Microsoft.UI.Colors.White)
        };

        var rssiBlock = new TextBlock
        {
            Text = $"RSSI {device.Rssi}",
            FontFamily = font, FontSize = 11,
            CharacterSpacing = 10, Foreground = new SolidColorBrush(Color.FromArgb(153, 255, 255, 255))
        };

        var leftStack = new StackPanel { Spacing = 3 };
        leftStack.Children.Add(nameBlock);
        leftStack.Children.Add(rssiBlock);

        // "VISIBLE" badge
        var badge = new Border
        {
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush(Color.FromArgb(10, 255, 255, 255)),
            BorderBrush = new SolidColorBrush(Color.FromArgb(46, 31, 158, 255)),
            BorderThickness = new Thickness(1),
            Padding = new Thickness(10, 4, 10, 4),
            Child = new TextBlock
            {
                Text = "VISIBLE",
                FontFamily = font, FontSize = 10,
                CharacterSpacing = 50,
                Foreground = new SolidColorBrush(Color.FromArgb(217, 26, 217, 255)) // auraCyan @ 0.85
            }
        };

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(leftStack, 0);
        Grid.SetColumn(badge, 1);
        grid.Children.Add(leftStack);
        grid.Children.Add(badge);

        return new Border
        {
            CornerRadius = new CornerRadius(14),
            Background = new SolidColorBrush(Color.FromArgb(13, 255, 255, 255)),
            BorderBrush = new SolidColorBrush(Color.FromArgb(36, 31, 158, 255)),
            BorderThickness = new Thickness(1),
            Padding = new Thickness(12),
            Child = grid
        };
    }
}
