Ja. Wir machen es jetzt direkt und sauber.

Für GitHub brauchst du den rohen Markdown-Inhalt. Kopiere ausschließlich den folgenden Inhalt in deine README.md. Die äußeren Schreib-Markierungen gehören nicht in die Datei.

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

On Ubuntu:

```bash
sudo apt install curl fuse3

Build

Make the build script executable:

chmod +x build.sh


Run the builder with your original AnycubicSlicerNext AppImage:

./build.sh /path/to/AnycubicSlicer.AppImage


The finished LinuxFix AppImage will be created automatically.

Make it executable:

chmod +x AnycubicSlicerNext-*-linux-x86_64-linuxfix.AppImage


Then simply double-click the AppImage to start AnycubicSlicerNext.

✨ Features
No external launcher required
No manual environment variables
Standalone AppImage
Automatically detects NVIDIA + Wayland
Uses Mesa Zink on affected configurations
Original AnycubicSlicerNext application remains unchanged
🖥️ Tested
Component	Tested
Ubuntu	26.04
Architecture	x86_64
GPU	NVIDIA RTX 3060
Driver	NVIDIA proprietary
Session	Wayland
AnycubicSlicerNext	1.3.9.4
3D viewport	Smooth
Print bed	Smooth

Other Linux distributions and GPUs are welcome for testing.

🔧 How it works

The build script extracts the original AppImage and adds a compatibility startup configuration.

On affected NVIDIA + Wayland systems, it enables the Mesa Zink rendering path before starting AnycubicSlicerNext.

The compatibility launcher is embedded directly into the generated AppImage.

There is no separate launcher to install or run.

📦 AppImageTool

You do not need to install appimagetool manually.

build.sh automatically downloads it when required.

⚠️ Disclaimer

This is an unofficial community project.

It is not affiliated with, endorsed by, or supported by Anycubic.

AnycubicSlicerNext and its associated components remain the property of their respective copyright holders.

📄 License

The LinuxFix scripts and original project code are released under the MIT License.

See LICENSE for details.


### Danach

Auf GitHub:

**Repository → `README.md` → ✏️ → gesamten alten Inhalt löschen → obigen Markdown-Inhalt einfügen → Commit changes**

GitHub rendert anschließend die `bash`-Blöcke automatisch als **Codefelder mit Kopier-Button**.

Für die eigentliche Projektseite würde ich danach als **nächsten Schritt direkt einen GitHub Release erstellen** und dein funktionierendes `AnycubicSlicerNext-1.3.9.4-linux-x86_64-linuxfix.AppImage` dort als Download hinterlegen. Das ist für normale Nutzer die sauberste Lösung.
