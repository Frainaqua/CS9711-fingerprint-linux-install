# CS9711 fingerprint linux install

## Project Background

Many Linux users rely on `fprintd` to enable fingerprint recognition on Linux devices. However, the CS9711 fingerprint reader is not supported by default in `fprintd`. Fortunately, the `libfprint-CS9711` project resolves this issue by enabling recognition of CS9711 devices. This project provides a simple tool to help users quickly install `libfprint-CS9711` and `fprintd`.

## Quick Start

This project is theoretically compatible with Debian-based distributions, including Ubuntu. You can run the installation directly using `One_click_bash.sh`. This script has only been tested on Ubuntu 24.04 LTS (x86 platform). If you encounter issues with bash or prefer to compile manually, a complete set of manual instructions is also provided.

## Full Manual Installation Steps

### Part 1: Build and Install libfprint-CS9711

libfprint-CS9711 Repository: [libfprint-CS9711](https://github.com/ddlsmurf/libfprint-CS9711)

Install required dependencies:

```bash
sudo apt update
sudo apt install -y \
  git meson ninja-build \
  build-essential \
  pkg-config \
  libglib2.0-dev \
  libusb-1.0-0-dev \
  libsystemd-dev \
  libfprint-2-dev \
  libdbus-1-dev \
  libgudev-1.0-dev
```

Clone the libfprint-CS9711 source:

```bash
git clone https://github.com/ddlsmurf/libfprint-CS9711.git
cd libfprint-CS9711
```

Build libfprint using Meson:

```bash
meson setup build
meson compile -C build
```

Install the built library into the system:

```bash
sudo meson install -C build
```

At this point, `libfprint-CS9711` has been installed on your system.

To check which `libfprint` version is currently used by `fprintd`, run:

```bash
ldd /usr/libexec/fprintd | grep libfprint-2.so.2
```

You should see something like:

```
libfprint-2.so.2 => /lib/x86_64-linux-gnu/libfprint-2.so.2
```

To confirm the installation path of `libfprint`, run:

```bash
sudo ldconfig
ldconfig -p | grep libfprint
```

You will likely see at least two entries:

* One path used by `fprintd` (e.g. `/lib/x86_64-linux-gnu/`)
* One path from your compiled version (e.g. `/usr/local/lib/x86_64-linux-gnu/`)

If `fprintd` is not using the `libfprint` version you built, it will not be able to properly communicate with your CS9711 fingerprint reader. To resolve this, you must recompile `fprintd` and link it against your version of `libfprint`.

### Part 2: Build and Install fprintd

fprintd Repository: [fprintd](https://gitlab.freedesktop.org/libfprint/fprintd)

**Important:** At the time of writing, the `master` branch of `fprintd` requires `libfprint` version **1.94.9 or higher**, but the latest `libfprint-CS9711` version is **1.94.6**, which is not compatible. Therefore, you must use an older version of `fprintd`. This project uses version **1.94.4**, which is compatible with `libfprint-CS9711`.

Download: [fprintd-v1.94.4.tar.gz](https://gitlab.freedesktop.org/libfprint/fprintd/-/archive/v1.94.4/fprintd-v1.94.4.tar.gz)

Install required dependencies:

```bash
sudo apt update
sudo apt install git meson ninja-build gettext libpam0g-dev libglib2.0-dev libdbus-1-dev \
  libgirepository1.0-dev libpolkit-gobject-1-dev python3-dbusmock \
  python3-dbus python3-pip python3-pydbus python3-gi-dev
```

Set `PKG_CONFIG_PATH` to prioritize your compiled `libfprint`:

```bash
export PKG_CONFIG_PATH=/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH
```

To check whether `pkg-config` is pointing to the correct `libfprint`, run:

```bash
pkg-config --modversion libfprint-2
```

It should return the version from `libfprint-CS9711`.

Enter the fprintd source directory:

```bash
cd fprint
```

Build fprintd:

```bash
meson setup builddir \
  --prefix=/usr \
  -Dpam_modules_dir=/lib/security
```

Compile the project:

```bash
ninja -C builddir
```

Install it:

```bash
sudo ninja -C builddir install
```

After completing all steps above, you can test fingerprint enrollment with:

```bash
fprintd-enroll
```

If it shows:

```
Enrolling right-index-finger finger.
```

Then `fprintd` has successfully recognized your CS9711 fingerprint device and is collecting a fingerprint sample.

To enable fingerprint login at system startup, run:

```bash
sudo pam-auth-update
```

And enable **"Fingerprint authentication"** in the dialog.

> ⚠ Since you're using non-standard versions of `libfprint` and `fprintd`, your system might attempt to upgrade them via APT. To prevent this, you can hold their versions:

```bash
sudo apt-mark hold fprintd libfprint-2-2 libfprint-2-dev
```

To check which packages are on hold:

```bash
apt-mark showhold
```

To unhold them:

```bash
sudo apt-mark unhold fprintd libfprint-2-2
```

(Optional) Use APT pinning to block upgrades:

```bash
sudo nano /etc/apt/preferences.d/fprintd
```

Add the following:

```
Package: fprintd
Pin: release *
Pin-Priority: -1

Package: libfprint-2-2
Pin: release *
Pin-Priority: -1
```

This tells APT to never install these packages from any source.

---

## Note and Warning

* **Warning:** The CS9711 driver is experimental and has not been thoroughly tested for false positives. Do not use it for critical security applications.
* Note that enrollment count is 15 touches, so insist a bit.
* Note also that this is based on an experimental image recognition from the sigfm proposal.
* For more notes, please refer to `readme.md` in the [libfprint-CS9711](https://github.com/ddlsmurf/libfprint-CS9711/blob/ericlinagora/cs9711-driver-cherried-onto-sigfm/README.md) repository.

---

## License

* The bash script and CS9711 driver are licensed under the MIT License (see LICENSE).
* This project includes unmodified source code of libfprint (version 1.94.6) and fprintd (version 1.94.4), licensed under the GNU Lesser General Public License v2.1 (see COPYING).
* Original authors of libfprint and fprintd are listed in AUTHORS.
* Section 6 of the license states that for compiled works that use this library, such works must include LibFPrint copyright notices alongside the copyright notices for the other parts of the work.
* Includes NBIS code from NIST under LGPL v2.1.

---

## Thanks

This project is built upon the open-source code of `libfprint-CS9711` and `fprintd`. Without the selfless contributions of these developers, this project would never have come to fruition. Therefore, special thanks to **Eric**, the publisher of `libfprint-CS9711`, and **Bastien Nocera** and **Daniel Drake**, the authors of `fprintd`.

As this is my first time coding a complete open-source project, my understanding of programming, operating systems, and open-source licenses may be limited. Thank you for your patience and understanding.

If you find this project helpful, please consider giving it a star or following me. If you have a great idea, feel free to submit issues or contribute code to the two projects mentioned above. Thank you for reading this far — wishing you all the best!