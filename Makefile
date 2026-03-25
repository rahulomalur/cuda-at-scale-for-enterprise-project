NVCC        = nvcc
CUDA_PATH   ?= /usr/local/cuda
CXX_FLAGS   = -std=c++17
INCLUDES    = -I$(CUDA_PATH)/include
NPP_LIBS    = -lnppc -lnppif -lnppig
CV_LIBS     = $(shell pkg-config --libs opencv4 2>/dev/null || pkg-config --libs opencv)
CV_INCLUDES = $(shell pkg-config --cflags opencv4 2>/dev/null || pkg-config --cflags opencv)

TARGET      = bin/blur.exe

all: build

build: src/main.cu
	@mkdir -p bin
	$(NVCC) $(CXX_FLAGS) $(INCLUDES) $(CV_INCLUDES) \
		src/main.cu -o $(TARGET) \
		$(NPP_LIBS) $(CV_LIBS)
	@echo "Build complete: $(TARGET)"

run: build
	./$(TARGET) -i data/images -o data/output

clean:
	rm -f $(TARGET)
	rm -f data/output/*.png data/output/*.tif data/output/*.jpg

.PHONY: all build run clean
