using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.Models;
using AuraConnect.Services;
using AuraConnect.Theme;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class UpdatesPage : Page
{
    private readonly BluetoothService _bt = App.Bluetooth;

    public UpdatesPage()
    {
        this.InitializeComponent();
        BuildPatchList();
    }

    private void BuildPatchList()
    {
        var font = AuraTheme.OxaniumFont;

        foreach (var p in Patch.Samples)
        {
            // Signed icon
            var icon = new FontIcon
            {
                Glyph = p.Signed ? "\uE735" : "\uE7BA",  // CheckMark or Warning
                FontSize = 18,
                Foreground = p.Signed ? AuraTheme.AuraBlueBrush : new SolidColorBrush(Microsoft.UI.Colors.Orange)
            };

            // Name + version + size row
            var nameBlock = new TextBlock
            {
                Text = $"{p.Name.ToUpperInvariant()}  {p.Version}",
                FontFamily = font, FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                CharacterSpacing = 40, Foreground = new SolidColorBrush(Microsoft.UI.Colors.White)
            };

            var sizeBlock = new TextBlock
            {
                Text = p.Size,
                FontFamily = font, FontSize = 11,
                CharacterSpacing = 10, Foreground = AuraTheme.WhiteBrush(0.6)
            };

            var nameRow = new Grid();
            nameRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            nameRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            Grid.SetColumn(nameBlock, 0);
            Grid.SetColumn(sizeBlock, 1);
            nameRow.Children.Add(nameBlock);
            nameRow.Children.Add(sizeBlock);

            // Summary
            var summaryBlock = new TextBlock
            {
                Text = p.Summary,
                FontFamily = font, FontSize = 12,
                CharacterSpacing = 10, Foreground = AuraTheme.WhiteBrush(0.7),
                TextWrapping = TextWrapping.Wrap
            };

            // Buttons
            var installBtn = new Button
            {
                Content = "INSTALL VIA BLUETOOTH",
                FontFamily = font, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                IsEnabled = _bt.IsConnected,
                Style = (Style)Application.Current.Resources["AccentButtonStyle"]
            };
            var detailsBtn = new Button
            {
                Content = "DETAILS",
                FontFamily = font, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Medium
            };

            var btnRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
            btnRow.Children.Add(installBtn);
            btnRow.Children.Add(detailsBtn);

            // Right column stack
            var rightStack = new StackPanel { Spacing = 6 };
            rightStack.Children.Add(nameRow);
            rightStack.Children.Add(summaryBlock);
            rightStack.Children.Add(btnRow);

            // Main row
            var mainGrid = new Grid { ColumnSpacing = 12 };
            mainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            mainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            Grid.SetColumn(icon, 0);
            Grid.SetColumn(rightStack, 1);
            icon.VerticalAlignment = VerticalAlignment.Top;
            icon.Margin = new Thickness(0, 2, 0, 0);
            mainGrid.Children.Add(icon);
            mainGrid.Children.Add(rightStack);

            PatchListPanel.Children.Add(new Border
            {
                CornerRadius = new CornerRadius(14),
                Background = new SolidColorBrush(Color.FromArgb(13, 255, 255, 255)),
                BorderBrush = new SolidColorBrush(Color.FromArgb(36, 31, 158, 255)),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(12),
                Child = mainGrid
            });
        }
    }
}
