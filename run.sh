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
    img = np.zeros((h, w), dtype=np.uint8)

    pattern = i % 5
    if pattern == 0:
        # Checkerboard — sharp edges, blur very obvious
        block = max(8, w // 16)
        for r in range(0, h, block):
            for c in range(0, w, block):
                if ((r // block) + (c // block)) % 2 == 0:
                    img[r:r+block, c:c+block] = 255

    elif pattern == 1:
        # Sharp white circles on black
        for _ in range(10):
            cx = np.random.randint(50, w - 50)
            cy = np.random.randint(50, h - 50)
            r = np.random.randint(10, 60)
            cv2.circle(img, (cx, cy), r, 255, -1)

    elif pattern == 2:
        # White text-like rectangles on black
        for _ in range(20):
            x1 = np.random.randint(0, w - 40)
            y1 = np.random.randint(0, h - 15)
            x2 = x1 + np.random.randint(20, 80)
            y2 = y1 + np.random.randint(5, 20)
            cv2.rectangle(img, (x1, y1), (x2, y2), 255, -1)

    elif pattern == 3:
        # Sharp diagonal stripes
        stripe_w = max(4, w // 32)
        for r in range(h):
            for c in range(w):
                if ((r + c) // stripe_w) % 2 == 0:
                    img[r, c] = 255

    elif pattern == 4:
        # Grid of sharp dots
        spacing = max(12, w // 20)
        for r in range(spacing, h - spacing, spacing):
            for c in range(spacing, w - spacing, spacing):
                cv2.circle(img, (c, r), 3, 255, -1)

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
