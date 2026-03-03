using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using AuraConnect.ViewModels;
using AuraConnect.Theme;
using Windows.UI;

namespace AuraConnect.Views;

public sealed partial class AiModulesPage : Page
{
    private readonly AiModulesViewModel _vm = new();

    public AiModulesPage()
    {
        this.InitializeComponent();
        BuildModuleList();
    }

    private void BuildModuleList()
    {
        var font = AuraTheme.OxaniumFont;

        foreach (var m in _vm.Modules)
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
                    Glyph = m.Icon, FontSize = 16,
                    Foreground = AuraTheme.BlueBrush(0.9),
                    HorizontalAlignment = HorizontalAlignment.Center,
                    VerticalAlignment = VerticalAlignment.Center
                }
            };

            // Title + badge
            var titleRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
            titleRow.Children.Add(new TextBlock
            {
                Text = m.Title.ToUpperInvariant(),
                FontFamily = font, FontSize = 12, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                CharacterSpacing = 55, Foreground = AuraTheme.WhiteBrush(0.90)
            });

            if (m.Badge is not null)
            {
                titleRow.Children.Add(new Border
                {
                    CornerRadius = new CornerRadius(10),
                    Background = new SolidColorBrush(Color.FromArgb(15, 255, 255, 255)),
                    BorderBrush = AuraTheme.BlueBrush(0.22),
                    BorderThickness = new Thickness(1),
                    Padding = new Thickness(8, 4, 8, 4),
                    Child = new TextBlock
                    {
                        Text = m.Badge,
                        FontFamily = font, FontSize = 10, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                        CharacterSpacing = 50, Foreground = AuraTheme.WhiteBrush(0.78)
                    }
                });
            }

            var subtitleBlock = new TextBlock
            {
                Text = m.Subtitle,
                FontFamily = font, FontSize = 12,
                Foreground = AuraTheme.WhiteBrush(0.62),
                TextWrapping = TextWrapping.Wrap, MaxLines = 2
            };

            var textStack = new StackPanel { Spacing = 4 };
            textStack.Children.Add(titleRow);
            textStack.Children.Add(subtitleBlock);

            // Download pill
            var downloadPill = new Border
            {
                CornerRadius = new CornerRadius(12),
                Background = new SolidColorBrush(Color.FromArgb(20, 255, 255, 255)),
                BorderBrush = AuraTheme.BlueBrush(0.28),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(10, 6, 10, 6),
                VerticalAlignment = VerticalAlignment.Center,
                Child = new TextBlock
                {
                    Text = "DOWNLOAD",
                    FontFamily = font, FontSize = 11, FontWeight = Microsoft.UI.Text.FontWeights.Medium,
                    CharacterSpacing = 50, Foreground = AuraTheme.WhiteBrush(0.86)
                }
            };

            // Main row
            var mainGrid = new Grid { ColumnSpacing = 12 };
            mainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            mainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            mainGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            Grid.SetColumn(iconBox, 0);
            Grid.SetColumn(textStack, 1);
            Grid.SetColumn(downloadPill, 2);
            iconBox.VerticalAlignment = VerticalAlignment.Center;
            mainGrid.Children.Add(iconBox);
            mainGrid.Children.Add(textStack);
            mainGrid.Children.Add(downloadPill);

            ModuleListPanel.Children.Add(new Border
            {
                CornerRadius = new CornerRadius(18),
                Background = new SolidColorBrush(Color.FromArgb(10, 255, 255, 255)),
                BorderBrush = new SolidColorBrush(Color.FromArgb(20, 255, 255, 255)),
                BorderThickness = new Thickness(1),
                Padding = new Thickness(12),
                Child = mainGrid
            });
        }
    }
}
