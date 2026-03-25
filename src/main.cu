#include <npp.h>
#include <nppi_filtering_functions.h>
#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <iostream>
#include <filesystem>
#include <chrono>
#include <vector>
#include <string>

namespace fs = std::filesystem;
using namespace cv;

// ─── Process one image: load → GPU blur → save ───────────────────────────────
void processImage(const std::string &inputPath, const std::string &outputPath)
{
    Mat img = imread(inputPath, IMREAD_GRAYSCALE);
    if (img.empty()) {
        std::cerr << "[SKIP] Cannot open: " << inputPath << "\n";
        return;
    }

    int cols = img.cols;
    int rows = img.rows;

    // Allocate NPP device buffers
    int srcStep, dstStep;
    Npp8u *d_src = nppiMalloc_8u_C1(cols, rows, &srcStep);
    Npp8u *d_dst = nppiMalloc_8u_C1(cols, rows, &dstStep);

    if (!d_src || !d_dst) {
        std::cerr << "[ERROR] NPP alloc failed for: " << inputPath << "\n";
        return;
    }

    // Host → Device
    cudaMemcpy2D(d_src, srcStep,
                 img.data, cols,
                 cols, rows,
                 cudaMemcpyHostToDevice);

    // Apply Gaussian blur via NPP — 5 passes of 15x15 kernel (GPU computation)
    // Multiple passes create a strong, clearly visible blur effect
    NppiSize roi      = {cols, rows};
    int numPasses     = 5;
    NppStatus status  = NPP_SUCCESS;

    for (int p = 0; p < numPasses && status == NPP_SUCCESS; p++) {
        // Ping-pong: src→dst on even passes, dst→src on odd passes
        if (p % 2 == 0) {
            status = nppiFilterGauss_8u_C1R(
                d_src, srcStep, d_dst, dstStep, roi,
                NPP_MASK_SIZE_15_X_15);
        } else {
            status = nppiFilterGauss_8u_C1R(
                d_dst, dstStep, d_src, srcStep, roi,
                NPP_MASK_SIZE_15_X_15);
        }
    }

    // Result is in d_dst if numPasses is odd, d_src if even
    Npp8u *d_result = (numPasses % 2 == 1) ? d_dst : d_src;
    int resultStep  = (numPasses % 2 == 1) ? dstStep : srcStep;

    if (status != NPP_SUCCESS) {
        std::cerr << "[ERROR] NPP filter failed (" << status << "): " << inputPath << "\n";
        nppiFree(d_src);
        nppiFree(d_dst);
        return;
    }

    // Device → Host
    Mat result(rows, cols, CV_8UC1);
    cudaMemcpy2D(result.data, cols,
                 d_result, resultStep,
                 cols, rows,
                 cudaMemcpyDeviceToHost);

    imwrite(outputPath, result);
    std::cout << "[OK] " << inputPath << " → " << outputPath << "\n";

    nppiFree(d_src);
    nppiFree(d_dst);
}

// ─── Main ─────────────────────────────────────────────────────────────────────
int main(int argc, char *argv[])
{
    std::string inputDir  = "data/images";
    std::string outputDir = "data/output";

    for (int i = 1; i < argc; i++) {
        std::string opt(argv[i]);
        if (opt == "-i" && i+1 < argc) inputDir  = argv[++i];
        if (opt == "-o" && i+1 < argc) outputDir = argv[++i];
    }

    fs::create_directories(outputDir);

    // Collect all supported image files
    std::vector<std::string> imagePaths;
    for (const auto &entry : fs::directory_iterator(inputDir)) {
        std::string ext = entry.path().extension().string();
        if (ext == ".png" || ext == ".jpg" || ext == ".tif" || ext == ".tiff")
            imagePaths.push_back(entry.path().string());
    }

    if (imagePaths.empty()) {
        std::cerr << "[ERROR] No images found in: " << inputDir << "\n";
        return 1;
    }

    std::cout << "Found " << imagePaths.size() << " images in " << inputDir << "\n";

    auto t0 = std::chrono::high_resolution_clock::now();

    for (const auto &path : imagePaths) {
        std::string filename = fs::path(path).filename().string();
        std::string outPath  = outputDir + "/" + filename;
        processImage(path, outPath);
    }

    auto t1 = std::chrono::high_resolution_clock::now();
    double elapsed = std::chrono::duration<double>(t1 - t0).count();

    std::cout << "\n=== Done ===\n";
    std::cout << "Processed : " << imagePaths.size() << " images\n";
    std::cout << "Total time : " << elapsed << " seconds\n";
    std::cout << "Throughput : " << (imagePaths.size() / elapsed) << " images/sec\n";

    return 0;
}
