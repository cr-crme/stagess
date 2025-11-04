# Makefile for compiling mydartproject with Dart

# Project name (output executable)
TARGET = stagess_backend
API_KEY_FILE = backendFirebaseServiceAccountKey.json

# Main Dart file
MAIN = bin/backend.dart

# Dart compiler
DART = dart

# Build directory
BUILD_DIR = build

# Service file for systemd
INSTALL_DIR = ~/services/$(TARGET)
LAUNCHER_FILE_NAME = $(TARGET).sh
LOG_FILE = stagess_backend.log

# Default target
all: compile launcher

# Compile Dart to native executable
compile:
	mkdir -p $(BUILD_DIR)
	cp $(API_KEY_FILE) ${BUILD_DIR}/
	$(DART) compile exe  \
		--define=STAGESS_USE_SSL=false \
		--define=STAGESS_BACKEND_PORT=3456 \
		$(MAIN) -o $(BUILD_DIR)/$(TARGET)

launcher:
	mkdir -p $(BUILD_DIR); \
	rm -f ${BUILD_DIR}/$(LAUNCHER_FILE_NAME); \
	touch ${BUILD_DIR}/$(LAUNCHER_FILE_NAME); \
	append_to_file() { echo "$$1" | tee -a ${BUILD_DIR}/$(LAUNCHER_FILE_NAME); }; \
	append_to_file "#!/bin/bash"; \
	append_to_file ""; \
	append_to_file "# Define the required exports"; \
	append_to_file "export STAGESS_FIREBASE_WEB_API_KEY=${STAGESS_FIREBASE_WEB_API_KEY}"; \
	append_to_file "export STAGESS_DATABASE_BACKEND=${STAGESS_DATABASE_BACKEND}"; \
	append_to_file "export STAGESS_DATABASE_DEV_PORT=${STAGESS_DATABASE_DEV_PORT}"; \
	append_to_file "export STAGESS_DATABASE_DEV_NAME=${STAGESS_DATABASE_DEV_NAME}"; \
	append_to_file "export STAGESS_DATABASE_DEV_USER=${STAGESS_DATABASE_DEV_USER}"; \
	append_to_file "export STAGESS_DATABASE_DEV_PASSWORD=${STAGESS_DATABASE_DEV_PASSWORD}"; \
	append_to_file "export STAGESS_DATABASE_PRODUCTION_PORT=${STAGESS_DATABASE_PRODUCTION_PORT}"; \
	append_to_file "export STAGESS_DATABASE_PRODUCTION_NAME=${STAGESS_DATABASE_PRODUCTION_NAME}"; \
	append_to_file "export STAGESS_DATABASE_PRODUCTION_USER=${STAGESS_DATABASE_PRODUCTION_USER}"; \
	append_to_file "export STAGESS_DATABASE_PRODUCTION_PASSWORD=${STAGESS_DATABASE_PRODUCTION_PASSWORD}"; \
	append_to_file ""; \
	append_to_file "# Define the log file name"; \
	append_to_file "LOG_FILE=$(LOG_FILE)"; \
	append_to_file ""; \
	append_to_file "# Run the backend"; \
	append_to_file "nohup ./$(TARGET)"; \
	append_to_file "current_date_time=\`date \"+%Y-%m-%d %H:%M:%S\"\`"; \
	append_to_file "echo \"The server has shutdown at \$$current_date_time... Damn...\" >> nohup.out";
	chmod +x ${BUILD_DIR}/$(LAUNCHER_FILE_NAME)


install: all
	mkdir -p $(INSTALL_DIR)
	cp $(BUILD_DIR)/$(TARGET) $(INSTALL_DIR)/
	cp $(BUILD_DIR)/$(API_KEY_FILE) $(INSTALL_DIR)/
	cp $(BUILD_DIR)/$(LAUNCHER_FILE_NAME) $(INSTALL_DIR)/

deploy: install

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

# Phony targets (not files)
.PHONY: all clean install deploy
