using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.ApplicationModel.DataTransfer;

namespace AuraConnect.Views;

public sealed partial class AccountPage : Page
{
    private const string DepositAddress = "LEDGER1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh";

    public AccountPage()
    {
        this.InitializeComponent();
    }

    private void OnCopyClick(object sender, RoutedEventArgs e)
    {
        var dp = new DataPackage();
        dp.SetText(DepositAddress);
        Clipboard.SetContent(dp);
    }
}
