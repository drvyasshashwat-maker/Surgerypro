#!/bin/bash
# ============================================================
# fix_build_issues.sh
# Run this as a pre-build script in Codemagic to fix:
#   1. isar_flutter_libs missing namespace in build.gradle
#   2. Kotlin version too old (needs >= 2.1.0)
# ============================================================

set -e

echo "=========================================="
echo " Step 1: Fix isar_flutter_libs namespace"
echo "=========================================="

ISAR_BUILD_GRADLE="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/build.gradle"

if [ -f "$ISAR_BUILD_GRADLE" ]; then
  echo "Found isar build.gradle at: $ISAR_BUILD_GRADLE"

  # Check if namespace is already set
  if grep -q "namespace" "$ISAR_BUILD_GRADLE"; then
    echo "Namespace already present, skipping patch."
  else
    # Read the package name from AndroidManifest.xml if it exists
    ISAR_MANIFEST="$HOME/.pub-cache/hosted/pub.dev/isar_flutter_libs-3.1.0+1/android/src/main/AndroidManifest.xml"
    NAMESPACE="dev.isar.isar_flutter_libs"

    if [ -f "$ISAR_MANIFEST" ]; then
      EXTRACTED=$(grep -o 'package="[^"]*"' "$ISAR_MANIFEST" | sed 's/package="//;s/"//' || true)
      if [ -n "$EXTRACTED" ]; then
        NAMESPACE="$EXTRACTED"
        echo "Extracted namespace from manifest: $NAMESPACE"
      fi
    fi

    echo "Injecting namespace '$NAMESPACE' into isar build.gradle..."

    # Insert namespace inside the android { } block
    sed -i.bak "/^android {/a\\    namespace '$NAMESPACE'" "$ISAR_BUILD_GRADLE"

    echo "Patched isar build.gradle successfully."
    echo "--- Patched content (first 40 lines) ---"
    head -40 "$ISAR_BUILD_GRADLE"
  fi
else
  echo "WARNING: isar build.gradle not found at expected path."
  echo "Searching for it..."
  FOUND=$(find "$HOME/.pub-cache" -name "build.gradle" -path "*isar_flutter_libs*" 2>/dev/null | head -5)
  if [ -n "$FOUND" ]; then
    echo "Found at: $FOUND"
    echo "Please update ISAR_BUILD_GRADLE path in this script."
  else
    echo "isar_flutter_libs not found in pub-cache. Run 'flutter pub get' first."
  fi
fi

echo ""
echo "=========================================="
echo " Step 2: Update Kotlin version to 2.1.0"
echo "=========================================="

SETTINGS_GRADLE="$CM_BUILD_DIR/android/settings.gradle"
TOP_BUILD_GRADLE="$CM_BUILD_DIR/android/build.gradle"

# Try settings.gradle first (new template style)
if [ -f "$SETTINGS_GRADLE" ]; then
  echo "Checking settings.gradle for Kotlin plugin..."
  if grep -q "org.jetbrains.kotlin.android" "$SETTINGS_GRADLE"; then
    sed -i.bak "s/org.jetbrains.kotlin.android.*version ['\"][^'\"]*['\"]/org.jetbrains.kotlin.android\" version \"2.1.0\"/g" "$SETTINGS_GRADLE"
    # Handle id(...) version(...) style
    sed -i "s/\(id[[:space:]]*\"org.jetbrains.kotlin.android\"[[:space:]]*version[[:space:]]*\)['\"][^'\"]*['\"]/\1\"2.1.0\"/g" "$SETTINGS_GRADLE"
    echo "Updated Kotlin version in settings.gradle"
    grep -n "kotlin" "$SETTINGS_GRADLE" || true
  else
    echo "Kotlin plugin not found in settings.gradle."
  fi
fi

# Try top-level build.gradle (old template style)
if [ -f "$TOP_BUILD_GRADLE" ]; then
  echo "Checking top-level build.gradle for ext.kotlin_version..."
  if grep -q "kotlin_version" "$TOP_BUILD_GRADLE"; then
    sed -i.bak "s/ext\.kotlin_version[[:space:]]*=[[:space:]]*['\"][^'\"]*['\"]/ext.kotlin_version = '2.1.0'/g" "$TOP_BUILD_GRADLE"
    echo "Updated ext.kotlin_version in build.gradle"
    grep -n "kotlin_version" "$TOP_BUILD_GRADLE" || true
  else
    echo "ext.kotlin_version not found in top-level build.gradle."
  fi
fi

echo ""
echo "=========================================="
echo " All fixes applied successfully!"
echo "==========================================”
