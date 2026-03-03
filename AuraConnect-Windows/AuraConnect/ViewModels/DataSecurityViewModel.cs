using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using AuraConnect.Models;

namespace AuraConnect.ViewModels;

public partial class DataSecurityViewModel : ObservableObject
{
    public ObservableCollection<SecurityDevice> Devices { get; } = new(SecurityDevice.Samples);

    [ObservableProperty] private string? _selectedDeviceId;
    [ObservableProperty] private bool _requirePhrase = true;

    public bool HasSelection => SelectedDeviceId is not null;

    public string SelectedDeviceName
    {
        get
        {
            if (SelectedDeviceId is null) return "No device selected.";
            var d = Devices.FirstOrDefault(x => x.Id == SelectedDeviceId);
            return d is not null ? $"Selected: {d.Name} \u2022 {d.KindLabel}" : "No device selected.";
        }
    }

    partial void OnSelectedDeviceIdChanged(string? value)
    {
        OnPropertyChanged(nameof(HasSelection));
        OnPropertyChanged(nameof(SelectedDeviceName));
        LockDeviceCommand.NotifyCanExecuteChanged();
        BrickNowCommand.NotifyCanExecuteChanged();
    }

    [RelayCommand(CanExecute = nameof(HasSelection))]
    private void LockDevice() { /* Stub */ }

    [RelayCommand(CanExecute = nameof(HasSelection))]
    private void BrickNow() { /* Stub */ }
}
