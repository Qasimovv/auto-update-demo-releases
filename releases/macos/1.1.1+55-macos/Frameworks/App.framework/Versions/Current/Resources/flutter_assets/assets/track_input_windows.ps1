param (
    [string]$output_file = "C:\Temp\input_events.txt"
)

# Create the directory if it doesn't exist
$dir = Split-Path $output_file
if (-Not (Test-Path $dir)) {
    New-Item -Path $dir -ItemType Directory
}

# Function to track input events
function Track-Input {
    Add-Type @"
        using System;
        using System.Windows.Forms;
        using System.Runtime.InteropServices;

        public class InputTracker {
            [DllImport("user32.dll")]
            public static extern int GetAsyncKeyState(Int32 i);

            public static void TrackInput(string outputPath) {
                using (System.IO.StreamWriter file = new System.IO.StreamWriter(outputPath, true)) {
                    while (true) {
                        for (int i = 0; i < 255; i++) {
                            int state = GetAsyncKeyState(i);
                            if (state == 32769) {
                                if (i >= 1 && i <= 2) {
                                    file.WriteLine("mouse_button_press");
                                } else {
                                    file.WriteLine("keyboard_key_press");
                                }
                                file.Flush();
                            }
                        }
                        System.Threading.Thread.Sleep(100);
                    }
                }
            }
        }
"@

    [InputTracker]::TrackInput($output_file)
}

Track-Input
