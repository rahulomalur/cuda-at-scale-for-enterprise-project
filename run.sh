#!/usr/bin/env bash
set -e

echo "=== Building ==="
make clean build

echo ""
echo "=== Downloading sample dataset (USC SIPI Misc) ==="
mkdir -p data/images data/output

if [ ! "$(ls -A data/images)" ]; then
    wget -q https://sipi.usc.edu/database/misc.zip -O /tmp/misc.zip
    unzip -q /tmp/misc.zip -d data/images/
    echo "Dataset ready."
else
    echo "Images already present, skipping download."
fi

echo ""
echo "=== Running GPU Blur ==="
./bin/blur.exe -i data/images -o data/output

echo ""
echo "=== Output images written to data/output/ ==="
ls data/output/ | head -20
