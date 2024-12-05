DEST_DIR = dist
BUILD_DIR = build
TARGET = v4l2ndi

# compiler & flags
CXX = g++
CFLAGS = -std=c++17 -pthread -Wl,--as-needed
LDFLAGS = 

# configurable ndi paths
NDI_PATH = $(shell echo $$NDI_PATH)
NDI_LIB_PATH ?= /usr/lib

# find all source files
SOURCES = $(wildcard *.cpp)
OBJS = $(patsubst %.cpp, $(BUILD_DIR)/%.o, $(SOURCES))
INCLUDES = -Iinclude -I$(NDI_PATH)/include

LD_PATHS = -L$(NDI_LIB_PATH) 
LD_LIBS = -lndi

.PHONY: all clean
all: $(DEST_DIR)/$(TARGET)

# build executable
$(DEST_DIR)/$(TARGET): $(OBJS)
	mkdir -p $(DEST_DIR)
	$(CXX) $(LDFLAGS) $(LD_PATHS) $^ -o $@ $(LD_LIBS)
	
# compile object files
$(BUILD_DIR)/%.o: %.cpp
	mkdir -p $(BUILD_DIR)
	$(CXX) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(DEST_DIR)/$(TARGET)
