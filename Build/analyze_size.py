#!/usr/bin/env python3
import json
from pathlib import Path
import matplotlib.pyplot as plt

# Release folder is parallel to this script
RELEASE_DIR = Path(__file__).parent.parent / "Release"

versions = []
rom_sizes = []
ram_sizes = []

# Loop over all ROM JSON files
for rom_file in sorted(RELEASE_DIR.glob("zephyr-*-rom.json")):
    ver = rom_file.stem.split("-")[1]  # extracts version like '3.7.1'
    ram_file = RELEASE_DIR / f"zephyr-{ver}-ram.json"
    
    # Load ROM
    with open(rom_file) as f:
        rom_data = json.load(f)
    rom = rom_data.get("flash", 0)  # Zephyr uses 'flash' for ROM
    
    # Load RAM
    if ram_file.exists():
        with open(ram_file) as f:
            ram_data = json.load(f)
        ram = ram_data.get("sram", 0)
    else:
        ram = 0
    
    versions.append(ver)
    rom_sizes.append(rom / 1024)  # convert bytes to KB
    ram_sizes.append(ram / 1024)

# Plot
fig, ax = plt.subplots(figsize=(8, 5))
width = 0.35
x = range(len(versions))

ax.bar([i - width/2 for i in x], rom_sizes, width, label="ROM (KB)", color="#1f77b4")
ax.bar([i + width/2 for i in x], ram_sizes, width, label="RAM (KB)", color="#ff7f0e")

ax.set_xticks(x)
ax.set_xticklabels(versions)
ax.set_ylabel("Size (KB)")
ax.set_xlabel("Zephyr Version")
ax.set_title("Zephyr RAM/ROM Usage Comparison")
ax.legend()
plt.tight_layout()
plt.show()
