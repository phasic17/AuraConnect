namespace AuraConnect.Models;

public class AuraDevice
{
    public ulong BluetoothAddress { get; init; }
    public string Name { get; set; } = "Aura Puck";
    public int Rssi { get; set; }

    public string Id => BluetoothAddress.ToString("X12");
}
