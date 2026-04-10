#!/bin/bash

APP_PATH="/Users/avinash.dimmeta/Library/Developer/Xcode/DerivedData/OurTrips-hkjuuhepqqfwwdcijtdiqecalufa/Build/Products/Debug-iphonesimulator/OurTrips.app"
DEVICE_1="F0B1A540-BF5E-43AB-8363-3D8285DFBEF2"
DEVICE_2="1EC068AB-38C7-4746-A950-2814B5ADC813"

echo "Installing updated app..."

xcrun simctl install "$DEVICE_1" "$APP_PATH"
echo "✓ Device 1 updated"

xcrun simctl install "$DEVICE_2" "$APP_PATH"
echo "✓ Device 2 updated"

echo ""
echo "✅ Trip sharing is now enabled!"
echo ""
echo "How to test:"
echo "1. Device 1: Create a trip"
echo "2. Device 1: Note the share code"
echo "3. Device 2: Join using that code"
echo "4. It should now work!"
