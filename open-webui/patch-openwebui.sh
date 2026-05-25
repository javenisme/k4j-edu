#!/bin/bash

# Patch OpenWebUI compiled files to remove OpenWebUI branding

BUILD_DIR="/app/build"

echo "Patching OpenWebUI files..."

# Replace in HTML
if [ -f "$BUILD_DIR/index.html" ]; then
    sed -i 's/Open WebUI/Chat/g' "$BUILD_DIR/index.html"
    echo "✓ Patched index.html"
fi

# Replace in compiled JavaScript files
find "$BUILD_DIR" -name "*.js" -type f | while read file; do
    if grep -q "OpenWebUI\|Share to OpenWebUI\|WebUI Settings" "$file" 2>/dev/null; then
        sed -i 's/OpenWebUI Community/Community/g' "$file"
        sed -i 's/Share to OpenWebUI Community/Share/g' "$file"
        sed -i 's/Help us translate Open WebUI!/Help translate/g' "$file"
        sed -i 's/WebUI Settings/Settings/g' "$file"
        sed -i "s|https://openwebui\.com|#|g" "$file"
        echo "✓ Patched $(basename $file)"
    fi
done

echo "Done! OpenWebUI branding removed."
