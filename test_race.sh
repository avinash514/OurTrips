#!/bin/bash
# OurTrips Multi-User Race Testing Script
# Simulates Need for Speed Most Wanted style racing with two drivers

echo "🏁 OurTrips Racing Simulator 🏁"
echo "================================"
echo ""

# Device IDs
DEVICE_1="F0B1A540-BF5E-43AB-8363-3D8285DFBEF2"  # iPhone 16 Pro (Leader)
DEVICE_2="1EC068AB-38C7-4746-A950-2814B5ADC813"  # iPhone 16 Pro Max (Chaser)

echo "📱 Devices:"
echo "  Device 1: iPhone 16 Pro (Leader)"
echo "  Device 2: iPhone 16 Pro Max (Chaser)"
echo ""

# Race route: San Francisco to Los Angeles
# Total distance: ~350 miles
# Simulation: 6 checkpoints

CHECKPOINTS=(
    "37.7749,-122.4194|San Francisco (Start)"
    "37.5000,-122.0000|Halfway to San Jose"
    "37.0000,-121.5000|San Jose Area"
    "36.5000,-120.5000|Fresno Area"
    "35.5000,-119.5000|Bakersfield"  
    "34.0522,-118.2437|Los Angeles (Finish)"
)

# Chaser is always slightly behind (0.05 degrees ~ 5km)
OFFSET=0.05

echo "🗺️  Race Route: San Francisco → Los Angeles"
echo "📏 Distance: ~350 miles (560 km)"
echo "👥 Racers: 2"
echo ""
echo "Press any key to start the race..."
read -n 1 -s
echo ""

race_progress=0
for checkpoint in "${CHECKPOINTS[@]}"; do
    IFS='|' read -r coords name <<< "$checkpoint"
    IFS=',' read -r lat lon <<< "$coords"
    
    # Calculate chaser position (behind by offset)
    chaser_lat=$(echo "$lat - $OFFSET" | bc)
    
    ((race_progress++))
    echo "📍 Checkpoint $race_progress/6: $name"
    echo "   Leader:  $lat, $lon"
    echo "   Chaser:  $chaser_lat, $lon"
    
    # Update Device 1 (Leader)
    xcrun simctl location "$DEVICE_1" set "$lat,$lon"
    
    # Update Device 2 (Chaser)  
    xcrun simctl location "$DEVICE_2" set "$chaser_lat,$lon"
    
    echo "   ✓ Positions updated"
    echo ""
    
    if [ $race_progress -lt 6 ]; then
        echo "⏱️  Next checkpoint in 10 seconds..."
        sleep 10
    fi
done

echo "🏆 Race Complete!"
echo ""
echo "📊 Final Positions:"
echo "   🥇 Device 1 (Leader) - Los Angeles"
echo "   🥈 Device 2 (Chaser) - 5km behind"
echo ""
echo "🔄 To see updates in the app:"
echo "   1. Both users should have the trip started"
echo "   2. Open Navigation on both devices"
echo "   3. Watch positions update in real-time"
echo ""
echo "💡 Tip: The app updates locations every 5 seconds automatically!"
