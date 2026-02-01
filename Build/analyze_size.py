#!/usr/bin/env python3
import json
from pathlib import Path
import matplotlib.pyplot as plt

# Folder containing zephyr-<ver>-ram.json and zephyr-<ver>-rom.json
RELEASE_DIR = Path(__file__).parent.parent / "Release"

versions = []
ram_sizes = []
rom_sizes = []

def load_total_size(json_file: Path) -> int:
    """
    Extract total size from Zephyr symbol tree JSON.
    """
    with open(json_file) as f:
        data = json.load(f)
    return data["symbols"]["size"]

# Iterate over ROM files and match RAM files by version
for rom_file in sorted(RELEASE_DIR.glob("zephyr-*-rom.json")):
    version = rom_file.stem.replace("zephyr-", "").replace("-rom", "")
    ram_file = RELEASE_DIR / f"zephyr-{version}-ram.json"

    if not ram_file.exists():
        print(f"Skipping {version}: RAM file missing")
        continue

    rom_size = load_total_size(rom_file)
    ram_size = load_total_size(ram_file)

    versions.append(version)
    rom_sizes.append(rom_size / 1024)  # KB
    ram_sizes.append(ram_size / 1024)  # KB

# Plot
fig, ax = plt.subplots(figsize=(9, 5))
x = range(len(versions))
width = 0.35

ax.bar([i - width / 2 for i in x], rom_sizes, width, label="ROM (KB)")
ax.bar([i + width / 2 for i in x], ram_sizes, width, label="RAM (KB)")

ax.set_xticks(x)
ax.set_xticklabels(versions)
ax.set_xlabel("Zephyr Version")
ax.set_ylabel("Size (KB)")
ax.set_title("Zephyr RAM and ROM Usage Comparison")
ax.legend()
ax.grid(axis="y", linestyle="--", alpha=0.5)

plt.tight_layout()
plt.show()
