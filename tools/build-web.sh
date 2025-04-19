#!/bin/bash

echo "🔨 Building web version..."
npx love.js ./src/ ./dist/web -c -t "Loading..."

echo "📚 Copying custom files..."
cp ./dist/love.css ./dist/web/theme/love.css
cp ./dist/favicon.ico ./dist/web/
cp ./dist/bg.png ./dist/web/theme/bg.png

echo "✨ Done!"