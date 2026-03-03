namespace AuraConnect.Models;

public record Patch(
    string Name,
    string Version,
    string Size,
    string Summary,
    bool Signed
)
{
    public string Id { get; } = Guid.NewGuid().ToString();

    public static List<Patch> Samples =>
    [
        new("Aura Core Firmware", "1.1.2", "18 MB", "Security hardening + BLE transfer stability.", true),
        new("Speech Model Pack", "v3", "92 MB", "Improved diarization and noise robustness.", true),
        new("RAG Index Optimizer", "0.9.7", "7 MB", "Faster ingestion and lower memory footprint.", true),
    ];
}
