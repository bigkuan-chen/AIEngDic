#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

echo "=== Downloading Flutter SDK (stable branch) ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# Add Flutter to the path
export PATH="$PATH:`pwd`/flutter/bin"

echo "=== Flutter Environment Info ==="
flutter doctor

echo "=== Enabling Flutter Web Support ==="
flutter config --enable-web

echo "=== Building Flutter Web (Release) ==="
flutter build web --release

echo "=== Build Completed Successfully ==="
