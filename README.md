# AnycubicSlicerNext LinuxFix

![Linux](https://img.shields.io/badge/Linux-x86__64-blue)
![Wayland](https://img.shields.io/badge/Wayland-tested-green)
![NVIDIA](https://img.shields.io/badge/NVIDIA-tested-green)
![License](https://img.shields.io/badge/license-MIT-blue)

**Unofficial Linux compatibility workaround for AnycubicSlicerNext.**

On some Linux systems, especially **NVIDIA + Wayland**, the 3D viewport and print bed can suffer from severe stuttering and extremely poor performance.

LinuxFix creates a new AppImage with an integrated compatibility workaround using **Mesa Zink**.

## 🚀 Quick Start

### Requirements

- Linux x86_64
- AnycubicSlicerNext AppImage
- `curl`
- `fuse3`

## 📥 Download

Download the `build.sh` file from this repository, or clone the repository with Git:

```bash
git clone https://github.com/myrko2026/anycubic-slicernext-linuxfix.git
cd anycubic-slicernext-linuxfix
```

### Build

Make the build script executable:

```bash
chmod +x build.sh
```

Run the build script with your original AnycubicSlicerNext AppImage:

```bash
./build.sh /path/to/AnycubicSlicer.AppImage
```

The script automatically downloads `appimagetool` if required and creates the LinuxFix AppImage.

### Start

Make the generated AppImage executable:

```bash
chmod +x AnycubicSlicerNext-*-linux-x86_64-linuxfix.AppImage
```

Then simply double-click the AppImage to start AnycubicSlicerNext.

## ✨ Features

- No external launcher required
- No manual environment variables
- Standalone AppImage
- Automatically detects NVIDIA + Wayland
- Uses Mesa Zink for the affected configuration
- Original application is preserved

## 🖥️ Tested

- Ubuntu 26.04
- x86_64
- NVIDIA GeForce RTX 3060
- NVIDIA proprietary driver
- Wayland
- AnycubicSlicerNext 1.3.9.4

The 3D viewport and print bed were tested successfully with smooth performance.

Other Linux distributions and GPUs are welcome for testing.

## 🔧 How it works

LinuxFix extracts the original AppImage and adds a compatibility configuration to its startup process.

On affected NVIDIA + Wayland systems, Mesa Zink is enabled before AnycubicSlicerNext starts.

The compatibility launcher is embedded directly into the generated AppImage.

No separate launcher is required.

## 📦 AppImageTool

`appimagetool` does not need to be installed manually.

The build script automatically downloads it when necessary.

## ⚠️ Disclaimer

This is an unofficial community project and is not affiliated with, endorsed by, or supported by Anycubic.

AnycubicSlicerNext and its associated components remain the property of their respective copyright holders.

## 📄 License

The LinuxFix scripts and project code are released under the MIT License.

See [LICENSE](LICENSE) for details.
