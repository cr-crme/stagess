@echo off
setlocal enabledelayedexpansion
REM Prevent script from stopping on errors
set "continue_on_error=true"

REM This script navigates all the subdirectories of the project
REM and runs the command "pub get" in each of them.

REM Currently translating the script from bash to batch
REM Usage: pubget.bat
REM This script is intended to be run from the root directory of the project.

REM Move to the script directory
cd /d "%~dp0"

REM Pub get in the stagess_common directory
pushd stagess_common
echo "Running pub get in stagess_common directory..."
call dart pub get
popd

REM Pub get in the stagess_common_flutter directory
pushd stagess_common_flutter
echo "Running pub get in stagess_common_flutter directory..."
call dart pub get
popd

REM Pub get in the external directory
pushd external\crcrme_material_theme
echo "Running pub get in external\crcrme_material_theme directory..."
call flutter pub get
popd
pushd external\enhanced_containers
pushd plugins\enhanced_containers_foundation
echo "Running pub get in external\enhanced_containers\plugins\enhanced_containers_foundation directory..."
call dart pub get
popd
call flutter pub get
popd
pushd external\pdf_generation
echo "Running pub get in external\pdf_generation directory..."
call flutter pub get
popd

REM Pub get in the stagess_reverse_proxy directory
pushd stagess_reverse_proxy
echo "Running pub get in stagess_reverse_proxy directory..."
call dart pub get
popd

REM Pub get in the stagess_backend directory
pushd stagess_backend
echo "Running pub get in stagess_backend directory..."
call dart pub get
pushd resources\backend_gui
echo "Running pub get in stagess_backend/resources/backend_gui directory..."
call flutter pub get
popd
popd

REM Pub get in the stagess directory
pushd stagess
echo "Running pub get in stagess directory..."
call flutter pub get
popd

REM Pub get in the stagess_admin directory
pushd stagess_admin
echo "Running pub get in stagess_admin directory..."
call flutter pub get
popd