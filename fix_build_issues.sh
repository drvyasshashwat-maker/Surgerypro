#!/bin/bash
set -e

echo "Step 1: Fix isar_flutter_libs namespace"

ISAR_BUILD_GRADLE="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle"
ISAR_MANIFEST="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/src/main/AndroidManifest.xml"

if [ ! -f "$ISAR_BUILD_GRADLE" ]; then
  echo "ERROR: isar build.gradle not found!"
  exit 1
fi

echo "Found isar build.gradle"

if grep -q "namespace" "$ISAR_BUILD_GRADLE"; then
  echo "Namespace already present, skipping."
else
  NAMESPACE="dev.isar.isar_flutter_libs"

  if [ -f "$ISAR_MANIFEST" ]; then
    EXTRACTED=$(grep -o 'package="[^"]*"' "$ISAR_MANIFEST" | sed 's/package="//;s/"//' || true)
    if [ -n "$EXTRACTED" ]; then
      NAMESPACE="$EXTRACTED"
    fi
  fi

  echo "Injecting namespace: $NAMESPACE"
  python3 patch_isar.py "$ISAR_BUILD_GRADLE" "$NAMESPACE"
  echo "Patched successfully."
fi

echo "Step 2: Update Kotlin version to 2.1.0"

SETTINGS_GRADLE="$CM_BUILD_DIR/android/settings.gradle"
TOP_BUILD_GRADLE="$CM_BUILD_DIR/android/build.gradle"

if [ -f "$SETTINGS_GRADLE" ]; then
  sed -i.bak 's/version "[0-9]*\.[0-9]*\.[0-9]*"/version "2.1.0"/g' "$SETTINGS_GRADLE"
  echo "Updated settings.gradle"
fi

if [ -f "$TOP_BUILD_GRADLE" ]; then
  sed -i.bak "s/ext.kotlin_version = .*/ext.kotlin_version = '2.1.0'/" "$TOP_BUILD_GRADLE"
  echo "Updated build.gradle"
fi

echo "All fixes applied!"
