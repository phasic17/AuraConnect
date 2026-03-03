using Microsoft.UI.Xaml;
using AuraConnect.Services;
using AuraConnect.ViewModels;

namespace AuraConnect;

public partial class App : Application
{
    public static BluetoothService Bluetooth { get; } = new();
    public static MainViewModel MainVM { get; } = new();

    private Window? _window;

    public App()
    {
        this.InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        _window = new Views.MainWindow();
        _window.Activate();
    }
}
