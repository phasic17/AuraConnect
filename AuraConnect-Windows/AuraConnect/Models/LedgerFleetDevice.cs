using CommunityToolkit.Mvvm.ComponentModel;

namespace AuraConnect.Models;

public partial class LedgerFleetDevice : ObservableObject
{
    public string Id { get; init; } = Guid.NewGuid().ToString();
    public string Name { get; init; } = string.Empty;
    public FleetDeviceKind Kind { get; init; }
    public double[] WeeklyUsage { get; init; } = [];

    [ObservableProperty]
    private double _allocated;

    public string KindLabel => Kind == FleetDeviceKind.Puck ? "Aura Puck" : "Farsight Rig";

    public string KindIcon => Kind == FleetDeviceKind.Puck
        ? "\uF0CE"   // GridView
        : "\uE977";  // HardDrive

    public enum FleetDeviceKind { Puck, Farsight }

    public static List<LedgerFleetDevice> Samples =>
    [
        new() { Name = "Paul's Puck", Kind = FleetDeviceKind.Puck, Allocated = 7_500, WeeklyUsage = [820, 910, 880, 1040, 990, 1200, 1110] },
        new() { Name = "Ops Puck #2", Kind = FleetDeviceKind.Puck, Allocated = 4_000, WeeklyUsage = [420, 470, 510, 460, 530, 600, 540] },
        new() { Name = "Clinic Puck", Kind = FleetDeviceKind.Puck, Allocated = 12_000, WeeklyUsage = [1200, 1350, 1290, 1480, 1410, 1600, 1520] },
        new() { Name = "Farsight \u2022 Lab", Kind = FleetDeviceKind.Farsight, Allocated = 25_000, WeeklyUsage = [2200, 2450, 2380, 2600, 2520, 2890, 2710] },
        new() { Name = "Farsight \u2022 Studio", Kind = FleetDeviceKind.Farsight, Allocated = 18_000, WeeklyUsage = [1600, 1750, 1690, 1880, 1810, 2100, 1980] },
    ];
}
