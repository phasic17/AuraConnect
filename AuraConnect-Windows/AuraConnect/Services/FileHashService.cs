using System.Security.Cryptography;

namespace AuraConnect.Services;

public static class FileHashService
{
    /// <summary>
    /// Computes SHA256 of a file, streaming in 1 MB chunks (matches macOS implementation).
    /// </summary>
    public static async Task<string> ComputeSha256Async(string filePath)
    {
        using var sha = SHA256.Create();
        using var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read, bufferSize: 1_048_576, useAsync: true);

        var buffer = new byte[1_048_576]; // 1 MB
        int bytesRead;
        while ((bytesRead = await stream.ReadAsync(buffer)) > 0)
        {
            sha.TransformBlock(buffer, 0, bytesRead, null, 0);
        }
        sha.TransformFinalBlock([], 0, 0);

        return Convert.ToHexString(sha.Hash!).ToLowerInvariant();
    }
}
