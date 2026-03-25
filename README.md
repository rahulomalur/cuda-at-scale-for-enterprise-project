# CUDA at Scale: Batch GPU Gaussian Blur

## Overview
This project applies a **3×3 Gaussian blur** to a large batch of grayscale
images entirely on the GPU using the **NVIDIA Performance Primitives (NPP)**
library. It demonstrates GPU-accelerated image processing at scale using
CUDA and NPP's `nppiFilterGauss_8u_C1R`.

## Dataset
Images sourced from the **USC SIPI Miscellaneous Image Database**
(https://sipi.usc.edu/database/database.php) — 39 images ranging from
256×256 to 1024×1024 pixels.

## Code Organization
- `src/main.cu`     — CUDA/NPP source code
- `data/images/`    — Input images
- `data/output/`    — Blurred output images
- `bin/`            — Compiled executable
- `Makefile`        — Build system
- `run.sh`          — Download data + build + run script
- `INSTALL`         — Installation instructions

## GPU Computation
Each image is processed with `nppiFilterGauss_8u_C1R`, an NPP function
that runs entirely on the GPU. Host↔device transfers use `cudaMemcpy2D`.

## How to Run
```bash
chmod +x run.sh
./run.sh
```
Or manually:
```bash
make build
./bin/blur.exe -i data/images -o data/output
```

## Example Output
```
Found 39 images in data/images
[OK] data/images/4.1.01.tiff → data/output/4.1.01.tiff
...
=== Done ===
Processed : 39 images
Total time : 0.847 seconds
Throughput : 46.05 images/sec
```
