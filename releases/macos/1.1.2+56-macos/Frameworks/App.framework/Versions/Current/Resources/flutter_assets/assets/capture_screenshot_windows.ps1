param (
    [string]$output_file
)

# Create the directory if it doesn't exist
$dir = Split-Path $output_file
if (-Not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory
}

# Capture the screenshot
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bitmap = New-Object Drawing.Bitmap $bounds.width, $bounds.height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$bitmap.Save($output_file, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

# Check if the screenshot was successfully created
if (Test-Path $output_file) {
    Write-Output $output_file
} else {
    Write-Error "Error: Failed to capture screenshot"
    exit 1
}
