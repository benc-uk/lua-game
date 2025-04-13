#!/bin/bash

DIR_NAME=$(dirname "$0")

SRC_PATH=$1
DEST_PATH=$2
LOVE_PATH=$3

# Check zip command is available
if ! command -v zip &> /dev/null
then
    echo "zip command could not be found. Please install it."
    exit 1
fi

# Set the default values if not provided
if [ -z "$SRC_PATH" ]; then
  SRC_PATH="$DIR_NAME/../src"
fi
if [ -z "$DEST_PATH" ]; then
  DEST_PATH="$DIR_NAME/../out"
fi
if [ -z "$LOVE_PATH" ]; then
  LOVE_PATH=$(which love)
fi

DEST_PATH="$(realpath "$DEST_PATH")"
SRC_PATH="$(realpath "$SRC_PATH")"

if [ -z "$LOVE_PATH" ]; then
  echo "Error: LOVE_PATH is not set and 'love' command not found in PATH."
  exit 1
fi

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_PATH"
rm "$DEST_PATH/out.love" 2> /dev/null
rm "$DEST_PATH/out" 2> /dev/null

# Compress the source files into a .love file
echo "📚 Compressing project"
cd "$SRC_PATH" || exit 1
zip -9 -r "$DEST_PATH/out.love" . > /dev/null

echo "✨ Created love file at $DEST_PATH/out.love"

# Cat love executable and .love file to create the final executable
echo "🔨 Building executable"
cat "$LOVE_PATH" "$DEST_PATH/out.love" > "$DEST_PATH/out"
chmod +x "$DEST_PATH/out"
echo "📦 Executable created at $DEST_PATH/out"