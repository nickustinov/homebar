#!/bin/bash

# Create xcassets structure for Phosphor icons
ASSETS_DIR="../macOSBridge/Assets.xcassets/PhosphorIcons"
REGULAR_SRC="package/assets/regular"
FILL_SRC="package/assets/fill"

# Create main directory
mkdir -p "$ASSETS_DIR"

# Create Contents.json for the folder
cat > "$ASSETS_DIR/Contents.json" << 'JSONEOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSONEOF

# Function to create imageset
create_imageset() {
    local name=$1
    local src_file=$2
    local dest_dir="$ASSETS_DIR/${name}.imageset"
    
    mkdir -p "$dest_dir"
    
    # Copy SVG
    cp "$src_file" "$dest_dir/${name}.svg"
    
    # Create Contents.json
    cat > "$dest_dir/Contents.json" << JSONEOF
{
  "images" : [
    {
      "filename" : "${name}.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "template"
  }
}
JSONEOF
}

# Process regular icons
echo "Processing regular icons..."
for svg in $REGULAR_SRC/*.svg; do
    filename=$(basename "$svg" .svg)
    create_imageset "ph.$filename" "$svg"
done

# Process fill icons  
echo "Processing fill icons..."
for svg in $FILL_SRC/*.svg; do
    filename=$(basename "$svg" .svg)
    # Fill files are named like "acorn-fill.svg", we want "ph.acorn.fill"
    base_name="${filename%-fill}"
    create_imageset "ph.${base_name}.fill" "$svg"
done

echo "Done! Created $(ls -d $ASSETS_DIR/*.imageset | wc -l) imagesets"
