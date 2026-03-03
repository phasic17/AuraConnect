using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using AuraConnect.Models;
using AuraConnect.Theme;

namespace AuraConnect.ViewModels;

public partial class LedgerUsageViewModel : ObservableObject
{
    [ObservableProperty] private double _totalBalance = 125_000;

    public ObservableCollection<LedgerFleetDevice> Devices { get; } = new(LedgerFleetDevice.Samples);

    public double[] SystemDaily { get; } = [6200, 7100, 6900, 8200, 7600, 9100, 7450];

    public double TotalAllocated => Devices.Sum(d => d.Allocated);
    public double Remaining => Math.Max(0, TotalBalance - TotalAllocated);
    public double AvgDaily => SystemDaily.Length > 0 ? SystemDaily.Average() : 0;

    public string FormattedBalance => AuraTheme.FormatLedger(TotalBalance);
    public string FormattedAllocated => AuraTheme.FormatLedger(TotalAllocated);
    public string FormattedRemaining => AuraTheme.FormatLedger(Remaining);
    public string FormattedAvgDaily => AuraTheme.FormatLedger(AvgDaily);
}
