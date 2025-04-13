# PowerShell Script to build a Love2D executable binary for Windows
# Usage: .\build-win.ps1 -srcPath "path\to\your\game" -outputPath "path\to\output\directory" 
# Example: .\build-win.ps1 -srcPath "C:\MyGame" -outputPath "C:\MyGame\build"

param (
    [string]$srcPath = "src",
    [string]$outputPath = "dist",
    [string]$lovePath = "C:\Program Files\LOVE\love.exe" # Uncomment to set a default path
)

# Check if srcPath and outputPath are provided
if (-Not $srcPath -or -Not $outputPath) {
    Write-Host "Usage: .\build-win.ps1 -srcPath 'path\to\your\game' -outputPath 'path\to\output\directory'"
    exit 1
}

# Check if srcPath exists
if (-Not (Test-Path $srcPath)) {
    Write-Host "Source path does not exist: $srcPath"
    exit 1
}

# Check if outputPath exists, if not create it
if (-Not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Compress the game folder into a .zip file
$zipFileName = Join-Path $outputPath "out.love"
$exeFileName = Join-Path $outputPath "out.exe"

# Remove existing files
if (Test-Path $zipFileName) {
    Remove-Item $zipFileName -Force
    Remove-Item $exeFileName -Force
}

echo "📚 Compressing project to: $zipFileName"
Compress-Archive -Path $srcPath\* -DestinationPath $zipFileName -Force

# Copy love.exe together with the .love file
echo "🔨 Building executable: $exeFileName"
Get-Content $lovePath,$zipFileName -AsByteStream | Set-Content $exeFileName -AsByteStream -Force

# Show the size of the executable in MB rounded to 2 decimal places
$size = "{0:N2} MB" -f ((Get-Item $exeFileName).length / 1MB)
echo "📦 Build complete! Size: $(${size})"