using Microsoft.UI;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.Services;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class MainWindow : Window
{
    private readonly BluetoothService _bt = App.Bluetooth;
    private string _currentSection = "Devices";
    private readonly Dictionary<string, Button> _navButtons = [];

    public MainWindow()
    {
        this.InitializeComponent();

        // Store dispatcher queue for BLE callbacks
        App.MainVM.DispatcherQueue = Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread();

        // Set window size
        var appWindow = this.AppWindow;
        appWindow.Resize(new Windows.Graphics.SizeInt32(1400, 900));
        appWindow.Title = "AuraConnect";

        // Dark title bar
        if (AppWindowTitleBar.IsCustomizationSupported())
        {
            var titleBar = appWindow.TitleBar;
            titleBar.ExtendsContentIntoTitleBar = true;
            titleBar.ButtonBackgroundColor = Colors.Transparent;
            titleBar.ButtonInactiveBackgroundColor = Colors.Transparent;
            titleBar.ButtonForegroundColor = Colors.White;
        }

        // Index nav buttons
        _navButtons["Devices"] = NavDevices;
        _navButtons["Transfer"] = NavTransfer;
        _navButtons["Updates"] = NavUpdates;
        _navButtons["AiModules"] = NavAiModules;
        _navButtons["Account"] = NavAccount;
        _navButtons["DataSecurity"] = NavDataSecurity;
        _navButtons["LedgerUsage"] = NavLedgerUsage;
        _navButtons["Identity"] = NavIdentity;
        _navButtons["Logs"] = NavLogs;

        // Subscribe to BT status changes
        _bt.PropertyChanged += OnBluetoothPropertyChanged;

        // Initial navigation
        NavigateTo("Devices");
        UpdateConnectionUI();
        UpdateStatusText();
    }

    private void OnNavClick(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Tag is string section)
        {
            NavigateTo(section);
        }
    }

    private void NavigateTo(string section)
    {
        _currentSection = section;

        Type? pageType = section switch
        {
            "Devices" => typeof(DevicesPage),
            "Transfer" => typeof(TransferPage),
            "Updates" => typeof(UpdatesPage),
            "AiModules" => typeof(AiModulesPage),
            "Account" => typeof(AccountPage),
            "DataSecurity" => typeof(DataSecurityPage),
            "LedgerUsage" => typeof(LedgerUsagePage),
            "Identity" => typeof(IdentityPage),
            "Logs" => typeof(LogsPage),
            _ => null
        };

        if (pageType is not null)
        {
            ContentFrame.Navigate(pageType);
        }

        UpdateNavHighlight();
        UpdateBackgroundEnergy();
    }

    private void UpdateNavHighlight()
    {
        foreach (var (key, btn) in _navButtons)
        {
            var isSelected = key == _currentSection;
            btn.Opacity = isSelected ? 1.0 : 0.74;

            // Show/hide left indicator by adjusting border
            btn.BorderThickness = isSelected
                ? new Thickness(2, 0, 0, 0)
                : new Thickness(0);
            btn.BorderBrush = isSelected
                ? new SolidColorBrush(Color.FromArgb(140, 31, 158, 255)) // auraBlue @ 0.55
                : null;
        }
    }

    private void UpdateConnectionUI()
    {
        var connected = _bt.IsConnected;
        ConnectionDot.Fill = connected
            ? new SolidColorBrush(Color.FromArgb(242, 26, 217, 255)) // auraCyan @ 0.95
            : new SolidColorBrush(Color.FromArgb(230, 255, 165, 0)); // orange @ 0.9
        ConnectionLabel.Text = connected ? "CONNECTED" : "NOT CONNECTED";
    }

    private void UpdateStatusText()
    {
        StatusText.Text = _bt.Status;
    }

    private void UpdateBackgroundEnergy()
    {
        BackgroundRenderer.Energy = _bt.IsSending ? 2.0 : (_bt.IsConnected ? 1.0 : 0.0);
    }

    private void OnBluetoothPropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(BluetoothService.Status))
            UpdateStatusText();
        if (e.PropertyName is nameof(BluetoothService.IsConnected) or nameof(BluetoothService.IsSending))
        {
            UpdateConnectionUI();
            UpdateBackgroundEnergy();
        }
    }
}
