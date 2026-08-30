AnycubicSlicerNext LinuxFix

Unofficial Linux workaround for AnycubicSlicerNext.

On some Linux systems, especially NVIDIA + Wayland, the 3D viewport and print bed can be extremely slow or stutter heavily.

LinuxFix creates a new AppImage that automatically enables a compatible Mesa Zink graphics configuration when needed.

Features
Works directly with the original AnycubicSlicerNext AppImage
No external launcher required
No manual environment variables
Result is a normal standalone AppImage
Automatically detects NVIDIA + Wayland
Uses Zink for the affected configuration
Build

Install the required tools:

sudo apt install curl fuse3


Make the script executable:

chmod +x build.sh


Build the LinuxFix AppImage:

./build.sh /path/to/AnycubicSlicer.AppImage


The finished AppImage will be created in the project directory.

Make it executable if necessary:

chmod +x AnycubicSlicerNext-*-linux-x86_64-linuxfix.AppImage


Then simply double-click the AppImage to start AnycubicSlicerNext.

Tested

Currently tested with:

Ubuntu 26.04
NVIDIA RTX 3060
NVIDIA proprietary driver
Wayland
AnycubicSlicerNext 1.3.9.4

Other Linux distributions and GPUs are welcome for testing.

Disclaimer

This is an unofficial community project and is not affiliated with or endorsed by Anycubic.

AnycubicSlicerNext remains the property of its respective copyright holders.
