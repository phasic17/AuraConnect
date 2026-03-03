namespace AuraConnect.Models;

public class SecurityDevice
{
    public string Id { get; init; } = Guid.NewGuid().ToString();
    public string Name { get; init; } = string.Empty;
    public DeviceKind Kind { get; init; }

    public string KindLabel => Kind switch
    {
        DeviceKind.Puck => "Aura Puck",
        DeviceKind.Farsight => "Farsight Rig",
        _ => "LedgerAI Device"
    };

    public string KindIcon => Kind switch
    {
        DeviceKind.Puck => "\uF0CE",        // GridView
        DeviceKind.Farsight => "\uE977",     // HardDrive
        _ => "\uF158"                        // Cube
    };

    public enum DeviceKind { Puck, Farsight, Other }

    public static List<SecurityDevice> Samples =>
    [
        new() { Name = "Paul's Puck", Kind = DeviceKind.Puck },
        new() { Name = "Ops Puck #2", Kind = DeviceKind.Puck },
        new() { Name = "Clinic Puck", Kind = DeviceKind.Puck },
        new() { Name = "Farsight \u2022 Lab", Kind = DeviceKind.Farsight },
        new() { Name = "LedgerAI Edge Node", Kind = DeviceKind.Other },
    ];
}
