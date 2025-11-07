# Makefile for compiling mydartproject with Dart

# Project name (output executable)
TARGET = stagess_reverse_proxy

# Main Dart file
MAIN = bin/stagess_reverse_proxy.dart

# Dart compiler
DART = dart

# Build directory
BUILD_DIR = build

# Service file for systemd
INSTALL_DIR = ~/services/$(TARGET)
LAUNCHER_FILE_NAME = $(TARGET).sh
LOG_FILE = stagess_reverse_proxy.log
SERVICE_FILE_NAME = $(TARGET).service
SERVICE_FILE_PATH = /etc/systemd/system/$(SERVICE_FILE_NAME)

# Default target
all: compile launcher service

# Compile Dart to native executable
compile:
	mkdir -p $(BUILD_DIR)
	$(DART) compile exe $(MAIN) -o $(BUILD_DIR)/$(TARGET)

launcher:
	mkdir -p $(BUILD_DIR); \
	rm -f ${BUILD_DIR}/$(LAUNCHER_FILE_NAME); \
	touch ${BUILD_DIR}/$(LAUNCHER_FILE_NAME); \
	append_to_file() { echo "$$1" | tee -a ${BUILD_DIR}/$(LAUNCHER_FILE_NAME); }; \
	append_to_file "#!/bin/bash"; \
	append_to_file ""; \
	append_to_file "# Define the required exports"; \
	append_to_file "export STAGESS_CERT_PEM=${STAGESS_CERT_PEM}"; \
	append_to_file "export STAGESS_KEY_PEM=${STAGESS_KEY_PEM}"; \
	append_to_file ""; \
	append_to_file "# Define the log file name"; \
	append_to_file "LOG_FILE=$(LOG_FILE)"; \
	append_to_file ""; \
	append_to_file "# Run the backend"; \
	append_to_file "./$(TARGET) > $(LOG_FILE) 2>&1"; \
	chmod +x ${BUILD_DIR}/$(LAUNCHER_FILE_NAME)

service:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(BUILD_DIR); \
	rm -f ${BUILD_DIR}/$(SERVICE_FILE_NAME); \
	touch ${BUILD_DIR}/$(SERVICE_FILE_NAME); \
	append_to_file() { echo "$$1" | tee -a ${BUILD_DIR}/$(SERVICE_FILE_NAME); }; \
	append_to_file "[Unit]"; \
	append_to_file "Description=$(TARGET) Dart Service"; \
	append_to_file "After=network.target"; \
	append_to_file ""; \
	append_to_file "[Service]"; \
	append_to_file "ExecStart=$(INSTALL_DIR)/$(LAUNCHER_FILE_NAME)"; \
	append_to_file "WorkingDirectory=$(INSTALL_DIR)"; \
	append_to_file "Restart=always"; \
	append_to_file "RestartSec=5"; \
	append_to_file "User=www-data"; \
	append_to_file "Environment=STAGESS_CERT_PEM="${STAGESS_CERT_PEM}""; \
	append_to_file "Environment=STAGESS_KEY_PEM="${STAGESS_KEY_PEM}""; \
	append_to_file "StandardOutput=file:$(INSTALL_DIR)/reverse_proxy.log"; \
	append_to_file "StandardError=file:$(INSTALL_DIR)/reverse_proxy_error.log"; \
	append_to_file ""; \
	append_to_file "[Install]"; \
	append_to_file "WantedBy=multi-user.target"; \

deamon: service
	sudo cp $(BUILD_DIR)/$(SERVICE_FILE_NAME) $(SERVICE_FILE_PATH)
	sudo systemctl daemon-reload
	sudo systemctl enable $(TARGET)
	sudo systemctl start $(TARGET)

install: all
	mkdir -p $(INSTALL_DIR)
	cp $(BUILD_DIR)/$(TARGET) $(INSTALL_DIR)/
	cp $(BUILD_DIR)/$(LAUNCHER_FILE_NAME) $(INSTALL_DIR)/

deploy: install deamon

# Clean build files
clean:
	rm -rf $(BUILD_DIR)

# Phony targets (not files)
.PHONY: all clean deamon install deploy service
