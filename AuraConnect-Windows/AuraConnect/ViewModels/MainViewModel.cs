using CommunityToolkit.Mvvm.ComponentModel;
using Microsoft.UI.Dispatching;
using AuraConnect.Services;

namespace AuraConnect.ViewModels;

public partial class MainViewModel : ObservableObject
{
    [ObservableProperty]
    private string _selectedSection = "Devices";

    public BluetoothService Bluetooth => App.Bluetooth;

    public DispatcherQueue? DispatcherQueue { get; set; }

    public double BackgroundEnergy =>
        Bluetooth.IsSending ? 2.0 : (Bluetooth.IsConnected ? 1.0 : 0.0);
}
