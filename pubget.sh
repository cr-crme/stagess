#!/usr/bin/env bash

# This script navigates all the subdirectories of the project
# and runs the command "pub get" in each of them.

# Usage: ./pubget.sh
# Make sure to give execute permission to the script
# chmod +x pubget.sh

# Move to the directory of the script
cd "$(dirname "$0")"

# Pub get in the stagess_common directory
pushd stagess_common
echo "Running pub get in stagess_common directory..."
dart pub get
popd

# Pub get in the stagess_common_flutter directory
pushd stagess_common_flutter
echo "Running pub get in stagess_common_flutter directory..."
flutter pub get
popd

# Pub get in the external directory
pushd external/crcrme_material_theme
echo "Running pub get in external/crcrme_material_theme directory..."
flutter pub get
popd
pushd external/enhanced_containers
pushd plugins/enhanced_containers_foundation
echo "Running pub get in external/enhanced_containers/plugins/enhanced_containers_foundation directory..."
dart pub get
popd
flutter pub get
popd
pushd external/pdf_generation
echo "Running pub get in external/pdf_generation directory..."
flutter pub get
popd

# Pub get in the stagess_reverse_proxy directory
pushd stagess_reverse_proxy
echo "Running pub get in stagess_reverse_proxy directory..."
dart pub get
popd

# Pub get in the stagess_backend directory
pushd stagess_backend
echo "Running pub get in stagess_backend directory..."
dart pub get
pushd resources/backend_gui
echo "Running pub get in stagess_backend/resources/backend_gui directory..."
flutter pub get
popd
popd

# Pub get in the stagess directory
pushd stagess
echo "Running pub get in stagess directory..."
flutter pub get
popd

# Pub get in the stagess_admin directory
pushd stagess_admin
echo "Running pub get in stagess_admin directory..."
flutter pub get
popd