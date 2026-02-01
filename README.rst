==============================
Zephyr Kernel Performance Test
==============================

This project compares the performance of different Zephyr RTOS kernels
on the **STM32 NUCLEO-F767ZI** board. It provides scripts to initialize
workspaces, download the ARM-only Zephyr SDK, build the test application,
and clean up all artifacts.

Directory Structure
-------------------

The project layout expected by the scripts::

    project-root/
    ├── Device/
    │   └── main.c              # Your test application
    ├── Build/
    │   ├── init.sh              # Initialize workspace, virtualenv, SDK
    │   ├── build.sh             # Build the application
    │   ├── clean.sh             # Remove artifacts
    │   └── Makefile             # Convenience wrapper
    └── versions/
        ├── zephyr-3.7.1/
        │   ├── west.yml         # Minimal manifest for this kernel version
        │   └── prj.conf         # Kernel configuration for NUCLEO-F767ZI
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

**Important:** the `west.yml` files go in the folder corresponding
to the Zephyr version you want to build, under `versions/<zephyr-version>/west.yml`.  
The scripts will pick the correct file automatically based on `ZEPHYR_VERSION`.

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

2. **Build the project** (runs initialization automatically):

   .. code-block:: bash

       cd Build
       make build

   This will:

   - Initialize Python virtual environment and West workspace for the selected version
   - Download the ARM-only Zephyr SDK (or full SDK for 3.7.1)
   - Build the application in `Device/` using the version-specific `prj.conf`  

3. **Clean all build artifacts**:

   .. code-block:: bash

       cd Build
       make clean

   This removes all SDKs, virtual environments, build directories, and West workspaces.

Custom Configuration
--------------------

- Each Zephyr version has its own `prj.conf` in `versions/<zephyr-version>/prj.conf`.  
- You can modify this file to enable/disable logging, adjust stack sizes, or change kernel settings.
- Each version also has its own `west.yml` in `versions/<zephyr-version>/west.yml`.  
- These minimal manifests include only the modules required for STM32: `hal_stm32` and `cmsis_6` (for 4.x).  
- **Do not move the `west.yml` outside its version folder**, or the scripts will not find it.

Performance Testing
-------------------

- Minimize logging in `prj.conf` for fair measurements.  
- Use cycle counters or timers in `main.c` to measure execution time.  
- Build and flash each version individually using:

  .. code-block:: bash

      ZEPHYR_VERSION=4.2 make build

Notes
-----

- **Idempotent initialization:** Running `init.sh` multiple times does not re-download SDKs or re-initialize workspaces.  
- **ARM-only toolchain:** Only the `arm-zephyr-eabi` toolchain is downloaded (except for 3.7.1, which uses the full SDK).  
- **West workspace isolation:** Each kernel version has its own workspace in `.build/<version>/west`.

