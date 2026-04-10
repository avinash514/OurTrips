# 🏁 Quick Start: Testing Multi-User Racing

## What's Ready

✅ **Two iPhone simulators running**
   - Device 1: iPhone 16 Pro (Leader)
   - Device 2: iPhone 16 Pro Max (Chaser)

✅ **OurTrips app installed on both**

✅ **Starting positions set:**  
   - Leader: San Francisco (37.7749, -122.4194)
   - Chaser: 500m behind (37.7699, -122.4244)

## How to Test the Racing Feature

### Step 1: Set Up Users (Do This Now!)

**On Device 1 (iPhone 16 Pro):**
1. Open OurTrips
2. Register as: `driver1@race.com` / `race123`
3. Go to **Trips** tab

**On Device 2 (iPhone 16 Pro Max):**
1. Open OurTrips
2. Register as: `driver2@race.com` / `race123`
3. Go to **Trips** tab

### Step 2: Create Race Trip (Device 1)

1. Tap **"+"** → **"Create Trip"**
2. Trip name: **"SF to LA Race"**
3. From: Tap **"Use Current Location"** (San Francisco)
4. To: Search **"Los Angeles, CA"**
5. Tap **"Create"**
6. Note the **Share Code** (8 characters)

### Step 3: Join Race (Device 2)

1. Tap **"+"** → **"Join Trip"**
2. Enter the **Share Code** from Device 1
3. Tap **"Join Trip"**
4. You're now in the race! 🏁

### Step 4: Start Racing! (Device 1)

1. Open the trip
2. Tap **"Start Trip"** (confirms)
3. Tap **"Start Navigation"**
4. You'll see:
   - Blue route from SF to LA
   - Your position (blue dot)
   - Device 2's position (purple car icon)
   - ETA, distance, time at top

### Step 5: View Race (Device 2)

1. Open the trip  
2. Tap **"Start Navigation"**
3. You'll see:
   - Same blue route
   - Leader's position (yellow star - owner)
   - Your position (blue dot)
   - Real-time updates every 5 seconds

## Racing Simulation

### Auto-Race Script
Run the prepared race simulation:
```bash
./test_race.sh
```

This will:
- Move both racers through 6 checkpoints
- SF → San Jose → Fresno → Bakersfield → LA
- Update positions every 10 seconds
- Show progress in terminal

### Manual Position Updates

Update positions anytime:
```bash
# Move Leader forward
xcrun simctl location F0B1A540-BF5E-43AB-8363-3D8285DFBEF2 set 37.5000,-122.0000

# Move Chaser (catching up!)
xcrun simctl location 1EC068AB-38C7-4746-A950-2814B5ADC813 set 37.4950,-122.0050
```

## What You'll See (Like NFS Most Wanted)

### On Navigation Map:
- **Blue Route Line** - The racing path
- **Yellow Star (Leader)** - Trip owner/Device 1
- **Purple Car (Chaser)** - Participant/Device 2
- **Blue Dot** - Your current position
- **Live Updates** - Positions update every 5 seconds

### Top Info Bar:
- ⏰ ETA to finish line
- 📏 Distance remaining
- ⏱️ Time remaining
- 👥 Active racers count

### Bottom Controls:
- 👥 See all racers
- 📍 Re-center map to view all racers

## Testing Checklist

- [ ] Both users registered
- [ ] Trip created by Device 1
- [ ] Device 2 joined using share code
- [ ] Trip started (status = Active)
- [ ] Both devices opened Navigation
- [ ] Both racers visible on map
- [ ] Positions updating (wait 5 sec)
- [ ] Route line displayed
- [ ] ETA/distance showing
- [ ] Run race simulation script
- [ ] Watch racers move along route!

## Pro Tips

🏎️ **Simulate overtaking:** Update chaser to be ahead of leader
🗺️ **View all racers:** Tap the re-center button (bottom right)
📊 **Check route details:** Tap list icon (top right)
🏁 **End race:** Tap "End Trip" when finished
❌ **Cancel race:** Tap "Cancel Trip" if needed

## Expected Behavior

✅ Both racers see each other in real-time
✅ Positions update every 5 seconds automatically
✅ Map auto-fits to show both racers
✅ Route displays from start to finish
✅ Each racer has unique icon/color
✅ Owner has star badge
✅ Distance between racers visible

## Troubleshooting

**Can't see other racer?**
- Wait 5-10 seconds for sync
- Check both are in "Active" trip
- Verify location permissions granted
- Ensure Navigation is open on both

**Positions not updating?**
- Close and reopen Navigation
- Check internet connection (simulation)
- Verify trip status is "Active"

**Race simulation not working?**
```bash
# Reset positions
xcrun simctl location F0B1A540-BF5E-43AB-8363-3D8285DFBEF2 set 37.7749,-122.4194
xcrun simctl location 1EC068AB-38C7-4746-A950-2814B5ADC813 set 37.7699,-122.4244
```

## Screenshots

Take screenshots to capture the race:
```bash
# Device 1
xcrun simctl io F0B1A540-BF5E-43AB-8363-3D8285DFBEF2 screenshot ~/Desktop/Racer1.png

# Device 2  
xcrun simctl io 1EC068AB-38C7-4746-A950-2814B5ADC813 screenshot ~/Desktop/Racer2.png
```

## Ready to Race! 🏁

Everything is set up. Just follow the steps above to start your multi-user racing test!
