==============================
Zephyr Kernel Performance Test
==============================

This project is designed to **compare the performance** of different Zephyr RTOS kernels
on the **STM32 NUCLEO-F767ZI** board. It provides scripts to initialize workspaces,
download ARM-only toolchains, build the test application, and clean up all artifacts.

Directory Structure
-------------------

The project has the following layout::

    project-root/
    ├── Device/
    │   └── main.c              # Your test application
    ├── Build/
    │   ├── init.sh              # Initialize workspace, toolchain, venv
    │   ├── build.sh             # Build the application for a given Zephyr version
    │   ├── clean.sh             # Remove all generated artifacts
    │   └── Makefile             # Convenience wrapper
    └── versions/
        ├── zephyr-3.7.1/
        │   ├── west.yml
        │   └── prj.conf
        ├── zephyr-4.0/
        │   ├── west.yml
        │   └── prj.conf
        ├── zephyr-4.1/
        │   ├── west.yml
        │   └── prj.conf
        ├── zephyr-4.2/
        │   ├── west.yml
        │   └── prj.conf
        └── zephyr-4.3/
            ├── west.yml
            └── prj.conf

Each Zephyr version is isolated with its own workspace, configuration, and ARM toolchain.

Requirements
------------

- Python 3.8+
- curl or wget
- tar
- bash shell
- STM32 NUCLEO-F767ZI board
- Internet connection (for West and Zephyr SDK downloads)

Usage
-----

1. **Set the Zephyr version** you want to build:

   .. code-block:: bash

       export ZEPHYR_VERSION=4.2

   Supported versions: `3.7.1`, `4.0`, `4.1`, `4.2`, `4.3`.

2. **Build the project**:

   .. code-block:: bash

       cd Build
       make build

   This will:

   - Initialize Python virtual environment and West workspace
   - Download the ARM-only Zephyr SDK for the selected version
   - Build the application located in `Device/` using the `prj.conf` for that version

3. **Clean all build artifacts**:

   .. code-block:: bash

       cd Build
       make clean

   This removes all SDKs, virtual environments, build directories, and West workspaces.

Custom Configuration
--------------------

- Each Zephyr version has its own `prj.conf` in `versions/<zephyr-version>/prj.conf`.  
- You can modify this file to enable/disable logging, adjust stack sizes, or change kernel settings.
- You can also replace `west.yml` for each version to point to custom Zephyr revisions.

Performance Testing
-------------------

- To compare kernel performance, ensure logging is minimized in `prj.conf` for fair measurements.
- You can use cycle counters or board timers in `main.c` to measure execution time of your test routines.
- Build and flash each version individually using `make build` with the appropriate `ZEPHYR_VERSION`.

Notes
-----

- **Idempotent initialization:** Running `init.sh` multiple times does not re-download SDKs or re-initialize workspaces.
- **ARM-only toolchain:** Only the `arm-zephyr-eabi` toolchain is downloaded, reducing disk usage and setup time.
- **West workspace isolation:** Each kernel version has its own workspace for reproducible builds.

