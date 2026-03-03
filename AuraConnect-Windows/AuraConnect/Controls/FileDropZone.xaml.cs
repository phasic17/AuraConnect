using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Windows.ApplicationModel.DataTransfer;
using Windows.UI;

namespace AuraConnect.Controls;

public sealed partial class FileDropZone : UserControl
{
    public event Action<IReadOnlyList<string>>? FilesDropped;

    public FileDropZone()
    {
        this.InitializeComponent();
    }

    private void OnDragOver(object sender, DragEventArgs e)
    {
        if (e.DataView.Contains(StandardDataFormats.StorageItems))
        {
            e.AcceptedOperation = DataPackageOperation.Copy;
            DropBorder.Background = new Microsoft.UI.Xaml.Media.SolidColorBrush(
                Color.FromArgb(31, 255, 255, 255)); // 0.12
            DropBorderBrush.Color = Color.FromArgb(140, 31, 158, 255); // 0.55
        }
    }

    private void OnDragLeave(object sender, DragEventArgs e)
    {
        DropBorder.Background = new Microsoft.UI.Xaml.Media.SolidColorBrush(
            Color.FromArgb(15, 255, 255, 255)); // 0.06
        DropBorderBrush.Color = Color.FromArgb(64, 31, 158, 255); // 0.25
    }

    private async void OnDrop(object sender, DragEventArgs e)
    {
        OnDragLeave(sender, e);

        if (e.DataView.Contains(StandardDataFormats.StorageItems))
        {
            var items = await e.DataView.GetStorageItemsAsync();
            var paths = items
                .Where(i => i is Windows.Storage.StorageFile)
                .Select(i => i.Path)
                .ToList();

            if (paths.Count > 0)
                FilesDropped?.Invoke(paths);
        }
    }
}
