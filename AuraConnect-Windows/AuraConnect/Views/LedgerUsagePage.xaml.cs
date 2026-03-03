using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.Models;
using AuraConnect.ViewModels;
using AuraConnect.Theme;
using AuraConnect.Controls;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class LedgerUsagePage : Page
{
    private readonly LedgerUsageViewModel _vm = new();

    public LedgerUsagePage()
    {
        this.InitializeComponent();
        PopulateData();
    }

    private void PopulateData()
    {
        TotalBalanceText.Text = _vm.FormattedBalance;
        AllocatedText.Text = _vm.FormattedAllocated;
        RemainingText.Text = _vm.FormattedRemaining;
        AvgDailyText.Text = $"AVG {_vm.FormattedAvgDaily}/DAY";
        AvgDailySummaryText.Text = _vm.FormattedAvgDaily;
        DeviceCountText.Text = _vm.Devices.Count.ToString();

        SystemChart.Values = _vm.SystemDaily;

        BuildDeviceBudgetRows();
    }

    private void BuildDeviceBudgetRows()
    {
        var font = AuraTheme.OxaniumFont;

        foreach (var d in _vm.Devices)
        {
            // Icon box
            var iconBox = new Border
            {
                Width = 44, Height = 44,
                CornerRadius = new CornerRadius(14),
                Background = new SolidColorBrush(Color.FromArgb(15, 255, 255, 255)),
                BorderBrush = new SolidColorBrush(Color.FromArgb(26, 255, 255, 255)),
                BorderThickness = new Thickness(1),
                Child = new FontIcon
                {
                    Glyph = d.KindIcon, FontSize = 16,
                    Foreground = AuraTheme.BlueBrush(0.9),
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center
                }
            };

            // Name stack
            var nameStack = new StackPanel { Spacing = 4 };
            nameStack.Children.Add(new TextBlock
            {
                Text = d.Name.ToUpperInvariant(),
                FontFamily = font, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                CharacterSpacing = 55, Foreground = AuraTheme.WhiteBrush(0.90)
            });
            nameStack.Children.Add(new TextBlock
            {
                Text = d.KindLabel,
                FontFamily = font, FontSize = 12,
                Foreground = AuraTheme.WhiteBrush(0.55)
            });

            // Sparkline
            var sparkline = new AuraSparkline
            {
                Width = 120, Height = 28,
                Values = d.WeeklyUsage,
                Opacity = 0.85
            };

            // Allocated column
            var allocStack = new StackPanel { Spacing = 4 };
            allocStack.Children.Add(new TextBlock
            {
                Text = "ALLOCATED",
                FontFamily = font, FontSize = 10, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                CharacterSpacing = 50, Foreground = AuraTheme.WhiteBrush(0.55),
                HorizontalAlignment = HorizontalAlignment.Right
            });
            var allocBox = new TextBox
            {
                Text = ((int)d.Allocated).ToString("N0"),
                Width = 150,
                FontFamily = font, FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
                TextAlignment = TextAlignment.Right
            };
            allocStack.Children.Add(allocBox);

            // Apply button
            var applyBtn = new Button
            {
                Style = (Style)Application.Current.Resources["AuraPillButtonStyle"],
                Content = "APPLY",
                VerticalAlignment = VerticalAlignment.Center
            };

            // Row grid
            var rowGrid = new Grid { ColumnSpacing = 12, Padding = new Thickness(0, 8, 0, 8) };
            rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            rowGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            Grid.SetColumn(iconBox, 0);
            Grid.SetColumn(nameStack, 1);
            Grid.SetColumn(sparkline, 2);
            Grid.SetColumn(allocStack, 3);
            Grid.SetColumn(applyBtn, 4);

            iconBox.VerticalAlignment = VerticalAlignment.Center;
            nameStack.VerticalAlignment = VerticalAlignment.Center;
            sparkline.VerticalAlignment = VerticalAlignment.Center;
            allocStack.VerticalAlignment = VerticalAlignment.Center;

            rowGrid.Children.Add(iconBox);
            rowGrid.Children.Add(nameStack);
            rowGrid.Children.Add(sparkline);
            rowGrid.Children.Add(allocStack);
            rowGrid.Children.Add(applyBtn);

            DeviceBudgetPanel.Children.Add(rowGrid);
        }
    }
}
