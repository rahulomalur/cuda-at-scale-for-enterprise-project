# CUDA at Scale: Batch GPU Gaussian Blur

## Overview
This project applies a **multi-pass 15×15 Gaussian blur** to a large batch of
grayscale images entirely on the GPU using the **NVIDIA Performance Primitives
(NPP)** library. It demonstrates GPU-accelerated image processing at scale
using CUDA and NPP's `nppiFilterGauss_8u_C1R`, processing 100 images with
5 blur passes each for a clearly visible smoothing effect.

## Dataset
100 programmatically generated grayscale test images at varying resolutions
(256×256, 512×512, 1024×1024) with five high-contrast pattern types:
- **Checkerboards** — sharp grid edges
- **Circles** — white circles on black background
- **Rectangles** — scattered white bars
- **Diagonal stripes** — alternating black/white diagonals
- **Dot grids** — evenly spaced small dots

Images are generated at runtime by `run.sh` using Python and OpenCV.

## Code Organization
- `src/main.cu`     — CUDA/NPP source code
- `data/images/`    — Input images (generated at runtime)
- `data/output/`    — Blurred output images
- `bin/`            — Compiled executable
- `Makefile`        — Build system
- `run.sh`          — Generate data + build + run script
- `INSTALL`         — Installation instructions

## GPU Computation
Each image is processed with `nppiFilterGauss_8u_C1R`, an NPP function
that runs entirely on the GPU. The blur is applied in **5 passes** using
a **15×15 Gaussian kernel** with ping-pong buffering between two GPU
buffers. Host↔device transfers use `cudaMemcpy2D`. No CPU-based filtering
is performed — all image processing happens on the GPU.

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
Found 100 images in data/images
[OK] data/images/sample_000.png → data/output/sample_000.png
[OK] data/images/sample_001.png → data/output/sample_001.png
...
=== Done ===
Processed : 100 images
Total time : 1.23 seconds
Throughput : 81.3 images/sec
```
