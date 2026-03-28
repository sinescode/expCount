import os
from PIL import Image

# --- CONFIGURATION ---
PROJECT_PATH = "android/app/src/main/res"
INPUT_IMAGE = "ggggggggg.jpg"          # ← Change if your file has a different name
ICON_NAME = "ic_launcher.png"

# Standard Android launcher icon sizes
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def generate_icons():
    if not os.path.exists(INPUT_IMAGE):
        print(f"❌ Error: '{INPUT_IMAGE}' not found in the current directory.")
        return

    print(f"🚀 Starting icon generation from {INPUT_IMAGE}...")

    try:
        # Open the source image once (JPG, PNG, etc. all work)
        with Image.open(INPUT_IMAGE) as img:
            for folder, size in SIZES.items():
                # Create directory if it doesn't exist
                out_dir = os.path.join(PROJECT_PATH, folder)
                os.makedirs(out_dir, exist_ok=True)
                if not os.path.exists(out_dir):  # only print if newly created
                    print(f"📁 Created directory: {folder}")

                output_path = os.path.join(out_dir, ICON_NAME)

                # High-quality resize to exact square size
                resized = img.resize((size, size), Image.Resampling.LANCZOS)
                resized.save(output_path, "PNG")   # always save as PNG

                print(f"✅ Saved: {folder}/{ICON_NAME} ({size}×{size})")

        print("\n✨ All icons generated successfully for Android!")

    except Exception as e:
        print(f"⚠️ An error occurred: {e}")


if __name__ == "__main__":
    generate_icons()