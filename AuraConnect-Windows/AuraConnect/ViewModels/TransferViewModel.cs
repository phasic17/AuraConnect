using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using AuraConnect.Models;
using AuraConnect.Services;

namespace AuraConnect.ViewModels;

public partial class TransferViewModel : ObservableObject
{
    private readonly BluetoothService _bt = App.Bluetooth;

    public ObservableCollection<AuraDevice> Devices { get; } = [];
    public ObservableCollection<QueuedFile> Queue { get; } = [];

    public string Status => _bt.Status;
    public bool IsConnected => _bt.IsConnected;
    public bool IsSending => _bt.IsSending;
    public double OverallProgress => _bt.OverallProgress;

    [ObservableProperty]
    private string? _selectedDeviceId;

    public TransferViewModel()
    {
        _bt.DevicesChanged += RefreshDevices;
        _bt.QueueChanged += RefreshQueue;
        _bt.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(BluetoothService.Status))
                OnPropertyChanged(nameof(Status));
            if (e.PropertyName == nameof(BluetoothService.IsConnected))
            {
                OnPropertyChanged(nameof(IsConnected));
                SendQueueCommand.NotifyCanExecuteChanged();
                LockNowCommand.NotifyCanExecuteChanged();
            }
            if (e.PropertyName == nameof(BluetoothService.IsSending))
            {
                OnPropertyChanged(nameof(IsSending));
                SendQueueCommand.NotifyCanExecuteChanged();
            }
            if (e.PropertyName == nameof(BluetoothService.OverallProgress))
                OnPropertyChanged(nameof(OverallProgress));
        };
    }

    [RelayCommand]
    private async Task ConnectAsync()
    {
        _bt.SelectedDeviceId = SelectedDeviceId;
        await _bt.ConnectSelectedAsync();
    }

    [RelayCommand]
    private void DisconnectDevice() => _bt.Disconnect();

    [RelayCommand(CanExecute = nameof(CanSend))]
    private async Task SendQueueAsync() => await _bt.SendQueuedFilesAsync();

    [RelayCommand]
    private void ClearQueue() => _bt.ClearQueue();

    [RelayCommand(CanExecute = nameof(IsConnected))]
    private void LockNow() => _bt.LockNow();

    private bool CanSend() => IsConnected && Queue.Count > 0 && !IsSending;

    public async Task AddFilesAsync(IEnumerable<string> paths)
    {
        await _bt.EnqueueFilesAsync(paths);
        RefreshQueue();
    }

    private void RefreshDevices()
    {
        Devices.Clear();
        foreach (var d in _bt.Devices) Devices.Add(d);
    }

    private void RefreshQueue()
    {
        Queue.Clear();
        foreach (var f in _bt.Queue) Queue.Add(f);
        SendQueueCommand.NotifyCanExecuteChanged();
    }
}
