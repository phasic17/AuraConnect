using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Windows.ApplicationModel.DataTransfer;

namespace AuraConnect.ViewModels;

public partial class AccountViewModel : ObservableObject
{
    [ObservableProperty] private double _ledgerBalance = 125_000;
    [ObservableProperty] private bool _invoiceMonthlyUsd = true;
    [ObservableProperty] private double _usdAmount = 250;

    public string DepositAddress { get; } = "LEDGER1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh";

    public string FormattedBalance => $"{(int)LedgerBalance:N0} $LEDGER";

    [RelayCommand]
    private void CopyAddress()
    {
        var dp = new DataPackage();
        dp.SetText(DepositAddress);
        Clipboard.SetContent(dp);
    }

    [RelayCommand]
    private void AddFunds() { /* Stub */ }

    [RelayCommand]
    private void BillMe() { /* Stub */ }
}
