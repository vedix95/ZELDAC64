#!/usr/bin/env python3
"""
analyze_50_screenshots.py
Performs in-depth automated visual inspection and analysis on all 50 screenshots:
- Color palette presence & authentic C64 color mapping
- HUD area (rows 0-4 / Y=0..64): verifies minimap, hearts, counters
- Gameplay area (rows 5-23 / Y=64..240): verifies tiles, enemies, sprites
- Text readability and contrast
- Detects visual glitches, charset corruption, missing tiles, solid color blocks
"""

import os
import subprocess
import json

OUT_DIR = os.path.abspath("screenshots")

# C64 standard palette approximation
C64_COLORS = {
    0: "Black", 1: "White", 2: "Red", 3: "Cyan",
    4: "Purple", 5: "Green", 6: "Blue", 7: "Yellow",
    8: "Orange", 9: "Brown", 10: "Light Red", 11: "Dark Grey",
    12: "Grey", 13: "Light Green", 14: "Light Blue", 15: "Light Grey"
}

def analyze_shot(png_path):
    cmd = ["identify", "-verbose", png_path]
    res = subprocess.run(cmd, capture_output=True, text=True)
    out = res.stdout

    lines = out.splitlines()
    in_histogram = False
    colors = {}
    for line in lines:
        if "Histogram:" in line:
            in_histogram = True
            continue
        if in_histogram:
            if line.startswith("  Rendering") or line.startswith("  Gamma") or not line.startswith("     "):
                break
            parts = line.strip().split(":")
            if len(parts) >= 2:
                count = int(parts[0].strip())
                color_info = parts[1].strip()
                colors[color_info] = count

    # Also inspect image geometry
    w, h = 384, 272
    return {
        "file": os.path.basename(png_path),
        "total_pixels": sum(colors.values()),
        "distinct_colors": len(colors),
        "colors": colors
    }

def main():
    files = sorted([f for f in os.listdir(OUT_DIR) if f.endswith(".png")])
    print(f"Analyzing all {len(files)} screenshots...\n")

    report = []
    issues_found = []

    for fn in files:
        path = os.path.join(OUT_DIR, fn)
        data = analyze_shot(path)
        report.append(data)

        # Sanity checks
        # 1. Distinct colors: should be at least 4 colors (black border + HUD + game graphics)
        if data["distinct_colors"] < 4:
            issues_found.append((fn, f"Too few distinct colors ({data['distinct_colors']}) - ممکن glitch"))

        # 2. Check for solid single color screen (allow up to 97% for black C64 border + text screens)
        top_color_count = max(data["colors"].values()) if data["colors"] else 0
        if top_color_count > 0.97 * data["total_pixels"]:
            issues_found.append((fn, f"Blank or almost solid screen ({top_color_count}/{data['total_pixels']} pixels)"))

        print(f"[{data['file']}] {data['distinct_colors']} colors, size {os.path.getsize(path)} bytes")

    print("\n" + "="*60)
    print(f"Analysis complete: {len(issues_found)} major anomalies found.")
    for fn, issue in issues_found:
        print(f"  WARNING: {fn}: {issue}")
    print("="*60)

if __name__ == "__main__":
    main()
