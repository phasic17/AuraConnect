using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.Models;
using AuraConnect.Services;
using AuraConnect.Theme;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class TransferPage : Page
{
    private readonly BluetoothService _bt = App.Bluetooth;

    public TransferPage()
    {
        this.InitializeComponent();
        DropZone.FilesDropped += OnFilesDropped;

        _bt.DevicesChanged += RefreshDevicePicker;
        _bt.QueueChanged += RefreshQueueList;
        _bt.PropertyChanged += OnBtPropertyChanged;

        RefreshDevicePicker();
        UpdateButtonStates();
    }

    private void OnDeviceSelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (DevicePicker.SelectedItem is AuraDevice device)
            _bt.SelectedDeviceId = device.Id;
    }

    private async void OnConnectClick(object sender, RoutedEventArgs e) => await _bt.ConnectSelectedAsync();
    private void OnDisconnectClick(object sender, RoutedEventArgs e) => _bt.Disconnect();
    private void OnLockClick(object sender, RoutedEventArgs e) => _bt.LockNow();
    private async void OnSendClick(object sender, RoutedEventArgs e) => await _bt.SendQueuedFilesAsync();
    private void OnClearClick(object sender, RoutedEventArgs e) => _bt.ClearQueue();

    private async void OnFilesDropped(IReadOnlyList<string> paths) =>
        await _bt.EnqueueFilesAsync(paths);

    private void RefreshDevicePicker()
    {
        var selected = DevicePicker.SelectedItem;
        DevicePicker.Items.Clear();
        foreach (var d in _bt.Devices)
            DevicePicker.Items.Add(d);
        DevicePicker.DisplayMemberPath = "Name";
        if (selected is AuraDevice prev && _bt.Devices.Any(d => d.Id == prev.Id))
            DevicePicker.SelectedItem = _bt.Devices.First(d => d.Id == prev.Id);
    }

    private void RefreshQueueList()
    {
        QueueListPanel.Children.Clear();

        if (_bt.Queue.Count == 0)
        {
            QueueListPanel.Children.Add(new TextBlock
            {
                Text = "NO FILES QUEUED.",
                FontFamily = AuraTheme.OxaniumFont,
                FontSize = 12, CharacterSpacing = 40,
                Foreground = new SolidColorBrush(Color.FromArgb(153, 255, 255, 255)),
                Margin = new Thickness(0, 6, 0, 0)
            });
            return;
        }

        foreach (var file in _bt.Queue)
            QueueListPanel.Children.Add(CreateFileCard(file));
    }

    private void OnBtPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(BluetoothService.OverallProgress))
            OverallProgressBar.Value = _bt.OverallProgress;
        if (e.PropertyName is nameof(BluetoothService.IsConnected) or nameof(BluetoothService.IsSending))
            UpdateButtonStates();
    }

    private void UpdateButtonStates()
    {
        ConnectButton.Visibility = _bt.IsConnected ? Visibility.Collapsed : Visibility.Visible;
        DisconnectButton.Visibility = _bt.IsConnected ? Visibility.Visible : Visibility.Collapsed;
        LockButton.IsEnabled = _bt.IsConnected;
        SendButton.IsEnabled = _bt.IsConnected && _bt.Queue.Count > 0 && !_bt.IsSending;
        ClearButton.IsEnabled = _bt.Queue.Count > 0;
    }

    private static UIElement CreateFileCard(QueuedFile file)
    {
        var font = AuraTheme.OxaniumFont;

        var nameBlock = new TextBlock
        {
            Text = file.Name,
            FontFamily = font, FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
            CharacterSpacing = 20, Foreground = new SolidColorBrush(Microsoft.UI.Colors.White),
            MaxLines = 1, TextTrimming = TextTrimming.CharacterEllipsis
        };

        var statusBlock = new TextBlock
        {
            Text = file.Status.ToUpperInvariant(),
            FontFamily = font, FontSize = 11,
            CharacterSpacing = 40, Foreground = AuraTheme.WhiteBrush(0.7)
        };

        var topRow = new Grid();
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        topRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(nameBlock, 0);
        Grid.SetColumn(statusBlock, 1);
        topRow.Children.Add(nameBlock);
        topRow.Children.Add(statusBlock);

        var progressBar = new ProgressBar
        {
            Minimum = 0, Maximum = 1, Value = file.Progress,
            Opacity = 0.95
        };

        var bytesBlock = new TextBlock
        {
            Text = $"{AuraTheme.FormatBytes(file.SentBytes)} / {AuraTheme.FormatBytes(file.Size)}",
            FontFamily = font, FontSize = 11,
            CharacterSpacing = 10, Foreground = AuraTheme.WhiteBrush(0.65)
        };

        var shaBlock = new TextBlock
        {
            Text = $"SHA {file.Sha256[..Math.Min(10, file.Sha256.Length)]}\u2026",
            FontFamily = font, FontSize = 11,
            CharacterSpacing = 10, Foreground = AuraTheme.WhiteBrush(0.45)
        };

        var bottomRow = new Grid();
        bottomRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bottomRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        Grid.SetColumn(bytesBlock, 0);
        Grid.SetColumn(shaBlock, 1);
        bottomRow.Children.Add(bytesBlock);
        bottomRow.Children.Add(shaBlock);

        var stack = new StackPanel { Spacing = 6 };
        stack.Children.Add(topRow);
        stack.Children.Add(progressBar);
        stack.Children.Add(bottomRow);

        return new Border
        {
            CornerRadius = new CornerRadius(14),
            Background = new SolidColorBrush(Color.FromArgb(13, 255, 255, 255)),
            BorderBrush = new SolidColorBrush(Color.FromArgb(36, 31, 158, 255)),
            BorderThickness = new Thickness(1),
            Padding = new Thickness(12),
            Child = stack
        };
    }
}
