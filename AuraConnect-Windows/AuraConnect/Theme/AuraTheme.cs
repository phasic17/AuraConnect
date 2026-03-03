using Microsoft.UI;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace AuraConnect.Theme;

public static class AuraTheme
{
    // Brand colors
    public static readonly Color AuraBlue = Color.FromArgb(255, 31, 158, 255);   // 0.12, 0.62, 1.00
    public static readonly Color AuraCyan = Color.FromArgb(255, 26, 217, 255);   // 0.10, 0.85, 1.00

    // Backgrounds
    public static readonly Color Bg0 = Colors.Black;
    public static readonly Color Bg1 = Color.FromArgb(230, 0, 0, 0);            // black @ 0.90

    // Surface tints
    public static readonly Color PanelTint = Color.FromArgb(9, 255, 255, 255);   // white @ 0.035
    public static readonly Color Stroke = Color.FromArgb(26, 255, 255, 255);     // white @ 0.10
    public static readonly Color TextDim = Color.FromArgb(179, 255, 255, 255);   // white @ 0.70
    public static readonly Color TextDim2 = Color.FromArgb(133, 255, 255, 255);  // white @ 0.52

    // Brushes (convenience)
    public static SolidColorBrush AuraBlueBrush => new(AuraBlue);
    public static SolidColorBrush AuraCyanBrush => new(AuraCyan);
    public static SolidColorBrush Bg0Brush => new(Bg0);
    public static SolidColorBrush TextDimBrush => new(TextDim);
    public static SolidColorBrush TextDim2Brush => new(TextDim2);

    public static SolidColorBrush WhiteBrush(double opacity) =>
        new(Color.FromArgb((byte)(255 * opacity), 255, 255, 255));

    public static SolidColorBrush BlueBrush(double opacity) =>
        new(Color.FromArgb((byte)(255 * opacity), AuraBlue.R, AuraBlue.G, AuraBlue.B));

    public static SolidColorBrush CyanBrush(double opacity) =>
        new(Color.FromArgb((byte)(255 * opacity), AuraCyan.R, AuraCyan.G, AuraCyan.B));

    // Font helpers
    public static FontFamily OxaniumFont => new("ms-appx:///Assets/Fonts/Oxanium-VariableFont_wght.ttf#Oxanium");

    // Sidebar gradient colors
    public static readonly Color SidebarTop = Color.FromArgb(255, 38, 38, 46);    // 0.15, 0.15, 0.18
    public static readonly Color SidebarMid = Color.FromArgb(255, 13, 13, 15);    // 0.05, 0.05, 0.06
    public static readonly Color SidebarBot = Color.FromArgb(255, 31, 31, 36);    // 0.12, 0.12, 0.14

    // Rail background deep lacquer
    public static readonly Color LacquerDark = Color.FromArgb(255, 5, 5, 6);      // 0.02, 0.02, 0.025
    public static readonly Color LacquerMid = Color.FromArgb(255, 9, 9, 11);      // 0.035, 0.035, 0.045

    // Helpers for size formatting
    public static string FormatBytes(long bytes)
    {
        string[] suffixes = ["B", "KB", "MB", "GB", "TB"];
        int order = 0;
        double size = bytes;
        while (size >= 1024 && order < suffixes.Length - 1)
        {
            order++;
            size /= 1024;
        }
        return $"{size:0.#} {suffixes[order]}";
    }

    public static string FormatLedger(double value) =>
        $"{(int)Math.Round(value):N0} $LEDGER";
}
