# PowerShell script to compare files between two directories and copy differences to a third directory

$DIR1 = "sort"
$DIR2 = "game"
$DIR3 = "patch"
$diffFound = $false

Write-Host ("Comparing files between {0} and {1}..." -f $DIR1, $DIR2)
Write-Host


function Get-RelativePath($base, $path) {
    $baseFull = [System.IO.Path]::GetFullPath($base)
    $pathFull = [System.IO.Path]::GetFullPath($path)
    $uriBase = New-Object System.Uri ($baseFull + [System.IO.Path]::DirectorySeparatorChar)
    $uriPath = New-Object System.Uri $pathFull
    $rel = $uriBase.MakeRelativeUri($uriPath).ToString()
    # Převést lomítka na zpětná lomítka pro Windows
    $rel = $rel -replace '/', '\'
    return $rel
}

# Get all files recursively in DIR1
Get-ChildItem -Path $DIR1 -Recurse -File | ForEach-Object {
    $file1 = $_.FullName
    $relativePath = Get-RelativePath $DIR1 $file1
    $file2 = Join-Path $DIR2 $relativePath
    $file3 = Join-Path $DIR3 $relativePath

    $copyFile = $false
    if (!(Test-Path $file2)) {
        Write-Host ("File exists in {0} but not in {1}: {2}" -f $DIR1, $DIR2, $file1)
        $copyFile = $true
        $diffFound = $true
    } else {
        $hash1 = Get-FileHash -Path $file1 -Algorithm SHA256
        $hash2 = Get-FileHash -Path $file2 -Algorithm SHA256
        if ($hash1.Hash -ne $hash2.Hash) {
            Write-Host ("File content differs: {0} <> {1}" -f $file1, $file2)
            $copyFile = $true
            $diffFound = $true
        }
    }
    if ($copyFile) {
        $destDir = Split-Path $file3 -Parent
        if (!(Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir | Out-Null
        }
        Copy-Item -Path $file1 -Destination $file3 -Force
        Write-Host ("Copying {0} to {1}" -f $file1, $file3)
    }
}

if (-not $diffFound) {
    Write-Host "All files are identical."
} else {
    Write-Host ("Differences were found and copied to {0}." -f $DIR3)
}

Pause
exit 0