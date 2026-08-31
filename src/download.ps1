<#
  Downloads a single URL to a file with a native PowerShell progress bar.
  Used by setup.bat instead of Invoke-WebRequest, since Invoke-WebRequest's
  own progress reporting is unreliable/slow for large files.
#>
param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][string]$OutFile
)

$ErrorActionPreference = "Stop"
$activity = "Downloading $(Split-Path $OutFile -Leaf)"

try {
    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.UserAgent = "LocalTranscriber-Setup"
    $response = $request.GetResponse()
    $totalBytes = $response.ContentLength
    $responseStream = $response.GetResponseStream()
    $outStream = [System.IO.File]::Create($OutFile)

    $buffer = New-Object byte[] 65536
    $totalRead = 0
    $lastPercent = -1

    while (($read = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        $outStream.Write($buffer, 0, $read)
        $totalRead += $read

        if ($totalBytes -gt 0) {
            $percent = [int](($totalRead / $totalBytes) * 100)
            if ($percent -ne $lastPercent) {
                $status = "$percent% ($([math]::Round($totalRead / 1MB, 1)) MB / $([math]::Round($totalBytes / 1MB, 1)) MB)"
                Write-Progress -Activity $activity -Status $status -PercentComplete $percent
                $lastPercent = $percent
            }
        }
    }

    Write-Progress -Activity $activity -Completed
    $outStream.Close()
    $responseStream.Close()
    $response.Close()
    exit 0
} catch {
    Write-Progress -Activity $activity -Completed
    Write-Host "Download failed: $_"
    exit 1
}
