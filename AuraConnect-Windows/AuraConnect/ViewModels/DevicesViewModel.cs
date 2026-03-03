using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using AuraConnect.Models;
using AuraConnect.Services;

namespace AuraConnect.ViewModels;

public partial class DevicesViewModel : ObservableObject
{
    private readonly BluetoothService _bt = App.Bluetooth;

    public ObservableCollection<AuraDevice> Devices { get; } = [];

    public string Status => _bt.Status;
    public bool IsScanning => _bt.IsScanning;

    public DevicesViewModel()
    {
        _bt.DevicesChanged += RefreshDevices;
        _bt.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(BluetoothService.Status))
                OnPropertyChanged(nameof(Status));
            if (e.PropertyName == nameof(BluetoothService.IsScanning))
                OnPropertyChanged(nameof(IsScanning));
        };
    }

    [RelayCommand]
    private void Scan() => _bt.StartScan();

    [RelayCommand]
    private void Stop() => _bt.StopScan();

    private void RefreshDevices()
    {
        Devices.Clear();
        foreach (var d in _bt.Devices)
            Devices.Add(d);
    }
}
