using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using AuraConnect.Models;
using AuraConnect.Services;

namespace AuraConnect.ViewModels;

public partial class UpdatesViewModel : ObservableObject
{
    private readonly BluetoothService _bt = App.Bluetooth;

    public ObservableCollection<Patch> Patches { get; } = new(Patch.Samples);

    public bool IsConnected => _bt.IsConnected;

    public UpdatesViewModel()
    {
        _bt.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(BluetoothService.IsConnected))
                OnPropertyChanged(nameof(IsConnected));
        };
    }
}
