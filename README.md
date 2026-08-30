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
