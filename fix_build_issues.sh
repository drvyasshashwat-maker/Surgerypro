#!/bin/bash
set -e

echo "=========================================="
echo " Step 1: Fix isar_flutter_libs namespace"
echo "=========================================="

ISAR_BUILD_GRADLE="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle"
ISAR_MANIFEST="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/src/main/AndroidManifest.xml"

if [ -f "$ISAR_BUILD_GRADLE" ]; then
  echo "Found isar build.gradle"

  if grep -q "namespace" "$ISAR_BUILD_GRADLE"; then
    echo "Namespace already present, skipping."
  else
    NAMESPACE="dev.isar.isar_flutter_libs"

    if [ -f "$ISAR_MANIFEST" ]; then
      EXTRACTED=$(grep -o 'package="[^"]*"' "$ISAR_MANIFEST" | sed 's/package="//;s/"//' || true)
      if [ -n "$EXTRACTED" ]; then
        NAMESPACE="$EXTRACTED"
        echo "Namespace: $NAMESPACE"
      fi
    fi

    python3 patch_isar.py "$ISAR_BUILD_GRADLE" "$NAMESPACE"
    echo "Patched successfully."
  fi
else
  echo "ERROR: isar build.gradle not found!"
  exit 1
fi

echo ""
echo "=========================================="
echo " Step 2: Update Kotlin version to 2.1.0"
echo "=========================================="

SETTINGS_GRADLE="$CM_BUILD_DIR/android/settings.gradle"
TOP_BUILD_GRADLE="$CM_BUILD_DIR/android/build.gradle"

if [ -f "$SETTINGS_GRADLE" ]; then
  if grep -q "org.jetbrains.kotlin.android" "$SETTINGS_GRADLE"; then
    sed -i.bak 's/org.jetbrains.kotlin.android" version "[^"]*"/org.jetbrains.kotlin.android" version "2.1.0"/g' "$SETTINGS_GRADLE"
    echo "Updated Kotlin in settings.gradle"
  fi
fi

if [ -f "$TOP_BUILD_GRADLE" ]; then
  if grep -q "kotlin_version" "$TOP_BUILD_GRADLE"; then
    sed -i.bak "s/ext\.kotlin_version *= *'[^']*'/ext.kotlin_version = '2.1.0'/g" "$TOP_BUILD_GRADLE"
    echo "Updated Kotlin in build.gradle"
  fi
fi

echo ""
echo "=========================================="
echo " All fixes applied!"
echo "==========================================”
