#!/usr/bin/env python3
import json
from pathlib import Path
import matplotlib.pyplot as plt
from collections import defaultdict

RELEASE_DIR = Path(__file__).parent.parent / "Release"


def classify_symbol(node):
    ident = node.get("identifier", "")

    # (no paths) / linker-generated symbols
    if ident.startswith(":/"):
        return "(no paths)"

    # Absolute paths (ZEPHYR_BASE)
    parts = ident.split("/")
    if parts and parts[0]:
        return parts[0]

    return "(unknown)"


def walk_symbols(node, acc):
    if "section" in node:
        bucket = classify_symbol(node)
        acc[bucket] += node.get("size", 0)

    for child in node.get("children", []):
        walk_symbols(child, acc)


def parse_file(path: Path):
    with open(path) as f:
        data = json.load(f)

    acc = defaultdict(int)
    walk_symbols(data["symbols"], acc)
    return acc


versions = []
ram_usage = defaultdict(list)
rom_usage = defaultdict(list)

all_buckets = set()

for rom_file in sorted(RELEASE_DIR.glob("zephyr-*-rom.json")):
    version = rom_file.stem.replace("zephyr-", "").replace("-rom", "")
    ram_file = RELEASE_DIR / f"zephyr-{version}-ram.json"

    if not ram_file.exists():
        continue

    rom_acc = parse_file(rom_file)
    ram_acc = parse_file(ram_file)

    versions.append(version)

    all_keys = set(rom_acc) | set(ram_acc)
    all_buckets |= all_keys

    for k in all_keys:
        rom_usage[k].append(rom_acc[k] / 1024)
        ram_usage[k].append(ram_acc[k] / 1024)

# Ensure every bucket has a value per version
for bucket in all_buckets:
    while len(rom_usage[bucket]) < len(versions):
        rom_usage[bucket].append(0.0)
    while len(ram_usage[bucket]) < len(versions):
        ram_usage[bucket].append(0.0)


# ---------- Plot helper ----------

def plot_stacked(ax, data, title, ylabel):
    x = range(len(versions))
    bottom = [0] * len(versions)

    # Sort by total size for stable, readable stacking
    for bucket, values in sorted(
        data.items(), key=lambda i: sum(i[1]), reverse=True
    ):
        if max(values) == 0:
            continue

        ax.bar(x, values, bottom=bottom, label=bucket)

        # Delta annotations
        for i in range(1, len(values)):
            delta = values[i] - values[i - 1]
            if abs(delta) >= 0.2:
                ax.text(
                    i,
                    bottom[i] + values[i],
                    f"{delta:+.1f}",
                    ha="center",
                    va="bottom",
                    fontsize=8,
                    rotation=90,
                )

        bottom = [b + v for b, v in zip(bottom, values)]

    ax.set_xticks(x)
    ax.set_xticklabels(versions)
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.legend(ncol=4, fontsize=9)
    ax.grid(axis="y", linestyle="--", alpha=0.4)


# ---------- RAM plot ----------

fig, ax = plt.subplots(figsize=(13, 5))
plot_stacked(
    ax,
    ram_usage,
    "RAM Usage per Zephyr Top-Level Component (with Deltas)",
    "RAM (KB)",
)
plt.tight_layout()
plt.show()


# ---------- ROM plot ----------

fig, ax = plt.subplots(figsize=(13, 5))
plot_stacked(
    ax,
    rom_usage,
    "ROM Usage per Zephyr Top-Level Component (with Deltas)",
    "ROM (KB)",
)
plt.tight_layout()
plt.show()
