# Makefile for ARM64v8 Shell

# Directories
SRC_DIR = src
BUILD_DIR = build
BIN_DIR = bin

# Source files
SRC_SOURCES = $(wildcard $(SRC_DIR)/*.s)
BUILTIN_SOURCES = $(wildcard $(SRC_DIR)/built-ins/*.s)
SOURCES = $(SRC_SOURCES) $(BUILTIN_SOURCES)

# Object files
SRC_OBJECTS = $(SRC_SOURCES:$(SRC_DIR)/%.s=$(BUILD_DIR)/%.o)
BUILTIN_OBJECTS = $(BUILTIN_SOURCES:$(SRC_DIR)/built-ins/%.s=$(BUILD_DIR)/built-ins/%.o)
OBJECTS = $(SRC_OBJECTS) $(BUILTIN_OBJECTS)

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
	@mkdir -p $(BUILD_DIR)/built-ins
	@mkdir -p $(BIN_DIR)

# Assemble source files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	$(AS) -o $@ $<

$(BUILD_DIR)/built-ins/%.o: $(SRC_DIR)/built-ins/%.s
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
