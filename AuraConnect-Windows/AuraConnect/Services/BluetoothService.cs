using System.Runtime.InteropServices.WindowsRuntime;
using System.Text;
using System.Text.Json;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.Advertisement;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Storage.Streams;
using CommunityToolkit.Mvvm.ComponentModel;
using AuraConnect.Models;

namespace AuraConnect.Services;

/// <summary>
/// Port of BluetoothManager.swift — BLE scanning, connection, GATT discovery, and file transfer.
/// Uses Windows.Devices.Bluetooth (WinRT built-in).
/// </summary>
public partial class BluetoothService : ObservableObject
{
    // BLE UUIDs (must match puck firmware)
    private static readonly Guid AURA_SERVICE_UUID = Guid.Parse("E7810A71-73AE-499D-8C15-FAA9AEF0C3F2");
    private static readonly Guid AURA_CTRL_UUID = Guid.Parse("E7810A71-73AE-499D-8C15-FAA9AEF0C3F3");
    private static readonly Guid AURA_DATA_UUID = Guid.Parse("E7810A71-73AE-499D-8C15-FAA9AEF0C3F4");

    // UI state
    [ObservableProperty] private string _status = "Ready.";
    [ObservableProperty] private bool _isConnected;
    [ObservableProperty] private bool _isScanning;
    [ObservableProperty] private bool _isSending;
    [ObservableProperty] private double _overallProgress;
    [ObservableProperty] private string? _selectedDeviceId;

    private readonly List<AuraDevice> _devices = [];
    public IReadOnlyList<AuraDevice> Devices => _devices;

    private readonly List<QueuedFile> _queue = [];
    public IReadOnlyList<QueuedFile> Queue => _queue;

    // BLE internals
    private BluetoothLEAdvertisementWatcher? _watcher;
    private BluetoothLEDevice? _connectedDevice;
    private GattCharacteristic? _ctrlChar;
    private GattCharacteristic? _dataChar;
    private GattSession? _session;
    private CancellationTokenSource? _sendCts;

    // Write pacing
    private readonly SemaphoreSlim _writeSemaphore = new(1, 1);

    public event Action? DevicesChanged;
    public event Action? QueueChanged;

    // ─── Scanning ────────────────────────────────────────────────

    public void StartScan()
    {
        _devices.Clear();
        SelectedDeviceId = null;
        DevicesChanged?.Invoke();

        IsScanning = true;
        Status = "Scanning\u2026 (puck must be in Transfer Mode)";

        _watcher = new BluetoothLEAdvertisementWatcher
        {
            ScanningMode = BluetoothLEScanningMode.Active
        };
        _watcher.AdvertisementFilter.Advertisement.ServiceUuids.Add(AURA_SERVICE_UUID);
        _watcher.Received += OnAdvertisementReceived;
        _watcher.Start();
    }

    public void StopScan()
    {
        if (_watcher is { Status: BluetoothLEAdvertisementWatcherStatus.Started })
        {
            _watcher.Stop();
        }
        _watcher = null;
        IsScanning = false;
        Status = _devices.Count == 0 ? "No Aura Pucks found." : "Select a puck to connect.";
    }

    private void OnAdvertisementReceived(BluetoothLEAdvertisementWatcher sender, BluetoothLEAdvertisementReceivedEventArgs args)
    {
        var name = args.Advertisement.LocalName;
        if (string.IsNullOrEmpty(name)) name = "Aura Puck";

        var device = new AuraDevice
        {
            BluetoothAddress = args.BluetoothAddress,
            Name = name,
            Rssi = args.RawSignalStrengthInDBm
        };

        // Dispatch to UI thread
        App.MainVM.DispatcherQueue?.TryEnqueue(() =>
        {
            var existing = _devices.FindIndex(d => d.BluetoothAddress == device.BluetoothAddress);
            if (existing >= 0)
                _devices[existing] = device;
            else
                _devices.Add(device);

            _devices.Sort((a, b) => b.Rssi.CompareTo(a.Rssi));
            DevicesChanged?.Invoke();
        });
    }

    // ─── Connection ──────────────────────────────────────────────

    public async Task ConnectSelectedAsync()
    {
        if (SelectedDeviceId is null)
        {
            Status = "Select a puck first.";
            return;
        }

        var target = _devices.FirstOrDefault(d => d.Id == SelectedDeviceId);
        if (target is null) { Status = "Device not found."; return; }

        StopScan();
        Status = $"Connecting to {target.Name}\u2026";

        _ctrlChar = null;
        _dataChar = null;

        try
        {
            _connectedDevice = await BluetoothLEDevice.FromBluetoothAddressAsync(target.BluetoothAddress);
            if (_connectedDevice is null) { Status = "Connect failed."; return; }

            _connectedDevice.ConnectionStatusChanged += OnConnectionStatusChanged;

            // Request higher MTU via GattSession
            _session = await GattSession.FromDeviceIdAsync(_connectedDevice.BluetoothDeviceId);
            _session.MaxPduSizeChanged += (s, e) => { };
            _session.MaintainConnection = true;

            Status = "Connected. Discovering services\u2026";

            // Discover GATT services
            var svcResult = await _connectedDevice.GetGattServicesForUuidAsync(AURA_SERVICE_UUID);
            if (svcResult.Status != GattCommunicationStatus.Success || svcResult.Services.Count == 0)
            {
                Status = "Aura service not found.";
                return;
            }

            var service = svcResult.Services[0];
            var charResult = await service.GetCharacteristicsAsync();
            if (charResult.Status != GattCommunicationStatus.Success)
            {
                Status = "Characteristic discovery failed.";
                return;
            }

            foreach (var c in charResult.Characteristics)
            {
                if (c.Uuid == AURA_CTRL_UUID) _ctrlChar = c;
                if (c.Uuid == AURA_DATA_UUID) _dataChar = c;
            }

            // Subscribe to CTRL notifications
            if (_ctrlChar is not null && _ctrlChar.CharacteristicProperties.HasFlag(GattCharacteristicProperties.Notify))
            {
                await _ctrlChar.WriteClientCharacteristicConfigurationDescriptorAsync(
                    GattClientCharacteristicConfigurationDescriptorValue.Notify);
                _ctrlChar.ValueChanged += OnCtrlValueChanged;
            }

            // DATA_PING test
            if (_dataChar is not null)
            {
                var payload = Encoding.UTF8.GetBytes("DATA_PING");
                var frame = BuildFrame(payload);
                var writeType = _dataChar.CharacteristicProperties.HasFlag(GattCharacteristicProperties.WriteWithoutResponse)
                    ? GattWriteOption.WriteWithoutResponse
                    : GattWriteOption.WriteWithResponse;
                await _dataChar.WriteValueAsync(frame.AsBuffer(), writeType);
            }

            IsConnected = _ctrlChar is not null && _dataChar is not null;
            Status = IsConnected ? "Connected. Ready to send." : "Missing ctrl/data characteristic on puck.";
        }
        catch (Exception ex)
        {
            Status = $"Connect failed: {ex.Message}";
            IsConnected = false;
        }
    }

    public void Disconnect()
    {
        StopSending();

        if (_ctrlChar is not null)
        {
            _ctrlChar.ValueChanged -= OnCtrlValueChanged;
        }

        _session?.Dispose();
        _session = null;
        _connectedDevice?.Dispose();
        _connectedDevice = null;
        _ctrlChar = null;
        _dataChar = null;
        IsConnected = false;
        Status = "Disconnected.";
    }

    public void LockNow()
    {
        _ = SendControlAsync(new { cmd = "ABORT" });
        Disconnect();
    }

    private void OnConnectionStatusChanged(BluetoothLEDevice sender, object args)
    {
        App.MainVM.DispatcherQueue?.TryEnqueue(() =>
        {
            if (sender.ConnectionStatus == BluetoothConnectionStatus.Disconnected)
            {
                IsConnected = false;
                _ctrlChar = null;
                _dataChar = null;
                Status = "Disconnected.";
            }
        });
    }

    private void OnCtrlValueChanged(GattCharacteristic sender, GattValueChangedEventArgs args)
    {
        var data = args.CharacteristicValue.ToArray();
        var text = Encoding.UTF8.GetString(data);
        App.MainVM.DispatcherQueue?.TryEnqueue(() => Status = text);
    }

    // ─── Queue Management ────────────────────────────────────────

    public async Task EnqueueFilesAsync(IEnumerable<string> filePaths)
    {
        foreach (var path in filePaths)
        {
            if (!File.Exists(path)) continue;

            var info = new FileInfo(path);
            if (info.Length <= 0) continue;

            var sha = await FileHashService.ComputeSha256Async(path);
            var file = new QueuedFile
            {
                FilePath = path,
                Name = info.Name,
                Size = info.Length,
                Sha256 = sha,
                SentBytes = 0,
                Status = "Queued"
            };
            _queue.Add(file);
        }
        RecomputeOverallProgress();
        QueueChanged?.Invoke();
        Status = $"Queued {_queue.Count} file(s).";
    }

    public void ClearQueue()
    {
        _queue.Clear();
        OverallProgress = 0;
        QueueChanged?.Invoke();
        Status = "Queue cleared.";
    }

    // ─── Transfer ────────────────────────────────────────────────

    public async Task SendQueuedFilesAsync()
    {
        if (!IsConnected) { Status = "Not connected."; return; }
        if (_queue.Count == 0) { Status = "Queue empty."; return; }
        if (_ctrlChar is null || _dataChar is null) { Status = "GATT not ready."; return; }
        if (IsSending) return;

        IsSending = true;
        Status = "Starting transfer\u2026";
        _sendCts = new CancellationTokenSource();

        try
        {
            await RunQueueAsync(_sendCts.Token);
        }
        finally
        {
            IsSending = false;
            RecomputeOverallProgress();
        }
    }

    public void StopSending()
    {
        _sendCts?.Cancel();
        _sendCts = null;
        IsSending = false;
    }

    private async Task RunQueueAsync(CancellationToken ct)
    {
        for (int i = 0; i < _queue.Count; i++)
        {
            if (ct.IsCancellationRequested) return;
            var file = _queue[i];
            if (file.Status == "Done") continue;

            file.Status = "Preparing\u2026";
            Status = $"Preparing {file.Name}\u2026";

            if (_connectedDevice is null || _ctrlChar is null || _dataChar is null)
            {
                Status = "Disconnected.";
                return;
            }

            // BEGIN command
            var begin = new
            {
                cmd = "BEGIN",
                id = file.Id,
                name = file.Name,
                size = file.Size,
                sha256 = file.Sha256
            };
            if (!await WriteControlJsonAsync(begin))
            {
                file.Status = "Failed (BEGIN)";
                continue;
            }

            // Brief delay for puck to initialize
            await Task.Delay(120, ct);

            // Stream data chunks
            try
            {
                file.Status = "Sending\u2026";
                Status = $"Sending {file.Name}\u2026";
                await StreamFileAsync(file, ct);
            }
            catch (OperationCanceledException)
            {
                return;
            }
            catch
            {
                file.Status = "Failed (data)";
                Status = $"Transfer failed: {file.Name}";
                continue;
            }

            // END command
            var end = new { cmd = "END", id = file.Id };
            await WriteControlJsonAsync(end);

            file.Status = "Done";
            file.SentBytes = file.Size;
            RecomputeOverallProgress();
            QueueChanged?.Invoke();

            // Brief gap between files
            await Task.Delay(120, ct);
        }

        Status = "All transfers complete.";
    }

    private async Task StreamFileAsync(QueuedFile file, CancellationToken ct)
    {
        using var stream = new FileStream(file.FilePath, FileMode.Open, FileAccess.Read, FileShare.Read, bufferSize: 65536, useAsync: true);

        // Determine max payload from session PDU size
        int maxPdu = _session?.MaxPduSize ?? 185;
        int payloadMax = Math.Max(64, maxPdu - 4); // 4 bytes for length prefix

        file.SentBytes = 0;
        RecomputeOverallProgress();

        var buffer = new byte[payloadMax];
        int bytesRead;
        while ((bytesRead = await stream.ReadAsync(buffer.AsMemory(0, payloadMax), ct)) > 0)
        {
            ct.ThrowIfCancellationRequested();

            var chunk = new byte[bytesRead];
            Array.Copy(buffer, chunk, bytesRead);
            var frame = BuildFrame(chunk);

            // Paced write
            await _writeSemaphore.WaitAsync(ct);
            try
            {
                var result = await _dataChar!.WriteValueAsync(
                    frame.AsBuffer(),
                    GattWriteOption.WriteWithoutResponse);

                if (result != GattCommunicationStatus.Success)
                    throw new IOException($"BLE write failed: {result}");
            }
            finally
            {
                _writeSemaphore.Release();
            }

            file.SentBytes = Math.Min(file.SentBytes + bytesRead, file.Size);
            RecomputeOverallProgress();
        }
    }

    // ─── Control Channel ─────────────────────────────────────────

    private async Task SendControlAsync(object command)
    {
        if (_connectedDevice is null || _ctrlChar is null) return;
        await WriteControlJsonAsync(command);
    }

    private async Task<bool> WriteControlJsonAsync(object command)
    {
        if (_ctrlChar is null) return false;
        try
        {
            var json = JsonSerializer.SerializeToUtf8Bytes(command);
            var result = await _ctrlChar.WriteValueAsync(
                json.AsBuffer(),
                GattWriteOption.WriteWithResponse);
            return result == GattCommunicationStatus.Success;
        }
        catch
        {
            return false;
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────

    private static byte[] BuildFrame(byte[] payload)
    {
        var frame = new byte[4 + payload.Length];
        BitConverter.TryWriteBytes(frame.AsSpan(0, 4), (uint)payload.Length); // Little-endian by default on Windows
        Array.Copy(payload, 0, frame, 4, payload.Length);
        return frame;
    }

    private void RecomputeOverallProgress()
    {
        long total = _queue.Sum(f => f.Size);
        if (total <= 0) { OverallProgress = 0; return; }
        long sent = _queue.Sum(f => Math.Min(f.SentBytes, f.Size));
        OverallProgress = (double)sent / total;
    }
}
