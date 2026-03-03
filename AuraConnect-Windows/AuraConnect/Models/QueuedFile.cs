using CommunityToolkit.Mvvm.ComponentModel;

namespace AuraConnect.Models;

public partial class QueuedFile : ObservableObject
{
    public string Id { get; init; } = Guid.NewGuid().ToString("D").ToLowerInvariant();
    public string FilePath { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public long Size { get; init; }
    public string Sha256 { get; init; } = string.Empty;

    [ObservableProperty]
    private long _sentBytes;

    [ObservableProperty]
    private string _status = "Queued";

    public double Progress => Size > 0 ? Math.Min((double)SentBytes / Size, 1.0) : 0.0;

    partial void OnSentBytesChanged(long value) => OnPropertyChanged(nameof(Progress));
}
