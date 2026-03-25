#!/usr/bin/env bash
set -e

echo "=== Building ==="
make clean build

echo ""
echo "=== Preparing sample dataset ==="
mkdir -p data/images data/output

# Check for actual image files
IMG_COUNT=$(find data/images -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.tif" -o -name "*.tiff" \) 2>/dev/null | wc -l)

if [ "$IMG_COUNT" -eq 0 ]; then
    echo "Generating 100 sample test images with Python+OpenCV..."
    python3 - <<'PYSCRIPT'
import numpy as np
import cv2
import os

out_dir = "data/images"
os.makedirs(out_dir, exist_ok=True)

np.random.seed(42)
sizes = [256, 512, 1024]

for i in range(100):
    h = w = sizes[i % len(sizes)]
    if i % 4 == 0:
        img = np.random.randint(0, 256, (h, w), dtype=np.uint8)
    elif i % 4 == 1:
        x = np.linspace(0, 255, w, dtype=np.uint8)
        img = np.tile(x, (h, 1))
    elif i % 4 == 2:
        y = np.linspace(0, 255, h, dtype=np.uint8).reshape(-1, 1)
        img = np.tile(y, (1, w))
    else:
        cx, cy = w // 2, h // 2
        Y, X = np.ogrid[:h, :w]
        r = np.sqrt((X - cx)**2 + (Y - cy)**2).astype(np.uint8)
        img = (r * 3).astype(np.uint8)

    fname = os.path.join(out_dir, f"sample_{i:03d}.png")
    cv2.imwrite(fname, img)

print(f"Generated 100 images in {out_dir}/")
PYSCRIPT
else
    echo "$IMG_COUNT images already present, skipping generation."
fi

echo ""
echo "=== Running GPU Blur ==="
./bin/blur.exe -i data/images -o data/output

echo ""
echo "=== Output images written to data/output/ ==="
echo "Total output files: $(ls data/output/ | wc -l)"
ls data/output/ | head -20
