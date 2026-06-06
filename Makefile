# Makefile for ARM64v8 Shell

# Directories
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin

# Source files
SOURCES = $(wildcard $(SRC_DIR)/*.s)

# Object files
OBJECTS = $(SOURCES:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)

# Executable
TARGET = $(BIN_DIR)/shell

# Assembler and linker
AS = as
LD = ld

# macOS SDK path
SDK_PATH = $(shell xcrun -sdk macosx --show-sdk-path)

# Default target
all: directories $(TARGET)

# Create directories
directories:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BIN_DIR)

# Assemble source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	$(AS) -o $@ $<

# Link object files
$(TARGET): $(OBJECTS)
	$(LD) -o $@ $^ -lSystem -syslibroot $(SDK_PATH)

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

# Run the shell
run: $(TARGET)
	$(TARGET)

.PHONY: all directories clean run
