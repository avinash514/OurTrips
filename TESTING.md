# OurTrips Multi-User Testing Guide

## Testing the Race-Style Multi-User Navigation

This guide shows how to test the app with multiple users tracking each other in real-time, similar to Need for Speed Most Wanted's race map.

## Current Implementation

The app already supports multi-user tracking with:
- **Real-time location updates** every 5 seconds
- **Color-coded markers** for each participant
- **Owner badge** (star icon) for trip creator
- **Participant badges** (car icons) for joiners
- **Live route display** with all users visible

## Testing Methods

### Method 1: Single Device Demo (Easiest)
The app automatically shows all participants on the navigation map when:
1. User creates a trip
2. Others join using share code
3. Owner starts the trip
4. Everyone opens navigation

**Simulated Locations:**
- Current implementation updates each user's location every 5 seconds
- Uses actual GPS from each device
- Shows real-time positions on map

### Method 2: Multiple Simulators (Best for Testing)

**Setup Two Users Racing:**

#### User 1 (Trip Owner):
```bash
# Boot iPhone 16 Pro (already running)
xcrun simctl boot "F0B1A540-BF5E-43AB-8363-3D8285DFBEF2"

# Set location (San Francisco - Starting Point)
xcrun simctl location "F0B1A540-BF5E-43AB-8363-3D8285DFBEF2" set 37.7749,-122.4194

# Install and run app
xcrun simctl install F0B1A540-BF5E-43AB-8363-3D8285DFBEF2 /path/to/OurTrips.app
xcrun simctl launch F0B1A540-BF5E-43AB-8363-3D8285DFBEF2 tryapps.OurTrips
```

#### User 2 (Joiner):
```bash
# Boot second device
xcrun simctl boot "1EC068AB-38C7-4746-A950-2814B5ADC813"

# Set different location (slightly behind on route)
xcrun simctl location "1EC068AB-38C7-4746-A950-2814B5ADC813" set 37.7699,-122.4194

# Install and run app
xcrun simctl install 1EC068AB-38C7-4746-A950-2814B5ADC813 /path/to/OurTrips.app
xcrun simctl launch 1EC068AB-38C7-4746-A950-2814B5ADC813 tryapps.OurTrips
```

### Method 3: Simulated Movement Along Route

To simulate users racing along a route:

```bash
# User 1 progressing along route (SF to LA)
xcrun simctl location DEVICE_1 set 37.7749,-122.4194  # Start
sleep 10
xcrun simctl location DEVICE_1 set 37.7549,-122.4094  # Moving
sleep 10
xcrun simctl location DEVICE_1 set 37.7349,-122.3994  # Further
sleep 10
xcrun simctl location DEVICE_1 set 37.7149,-122.3894  # Even further

# User 2 trailing behind
xcrun simctl location DEVICE_2 set 37.7699,-122.4194  # Behind start
sleep 10
xcrun simctl location DEVICE_2 set 37.7499,-122.4094  # Catching up
sleep 10
xcrun simctl location DEVICE_2 set 37.7299,-122.3994  # Still trailing
```

## Testing Workflow

### Step 1: Register Two Users
**Device 1:**
- Open app
- Register as: driver1@test.com / password: test123

**Device 2:**
- Open app
- Register as: driver2@test.com / password: test123

### Step 2: Create Trip (Device 1)
1. Go to Trips tab
2. Tap "+" → "Create Trip"
3. Name: "Race to LA"
4. From: San Francisco, CA
5. To: Los Angeles, CA
6. Create trip
7. Share trip code (e.g., "ABC12345")

### Step 3: Join Trip (Device 2)
1. Go to Trips tab
2. Tap "+" → "Join Trip"
3. Enter share code: "ABC12345"
4. Tap "Join Trip"

### Step 4: Start Racing
**Device 1 (Owner):**
1. Open trip details
2. Tap "Start Trip"
3. Tap "Start Navigation"
4. See route with both participants

**Device 2 (Joiner):**
1. Open trip details
2. Tap "Start Navigation"
3. See route with both participants

### Step 5: Simulate Racing
Update locations to simulate movement:
- Both users' positions update every 5 seconds
- Map shows both drivers in real-time
- Blue route line shows the path
- Each driver has unique colored marker

## Visual Features (Like NFS Most Wanted)

✅ **Real-time opponent tracking** - See other drivers' positions
✅ **Color-coded identifiers** - Owner (yellow/star), Participants (purple/car)
✅ **Route overlay** - Blue line showing the race path
✅ **Distance/ETA info** - Top bar shows progress
✅ **Auto-zoom** - Camera fits all racers on screen
✅ **Participant list** - See who's online and racing

## Expected Behavior

When racing with multiple users:
- **Owner**: Yellow circle with star icon
- **Participants**: Purple circles with car icons
- **Your location**: Blue dot (highlighted)
- **Route**: Blue polyline connecting start to finish
- **Updates**: Every 5 seconds, positions refresh

## Demo Locations (SF to LA Route)

You can use these coordinates to simulate a race:

```
Start:    37.7749, -122.4194  (San Francisco)
Point 1:  37.5000, -122.0000  (Between)
Point 2:  37.0000, -121.5000  (Halfway)
Point 3:  36.5000, -120.5000  (Getting close)
Point 4:  35.5000, -119.5000  (Almost there)
Finish:   34.0522, -118.2437  (Los Angeles)
```

## Troubleshooting

**Participants not showing?**
- Ensure both devices have location permissions
- Check both users are in the same trip
- Verify trip status is "Active"
- Wait 5 seconds for location sync

**Route not displaying?**
- Trip must be started (Active status)
- Navigation must be opened
- Route calculation may take a few seconds

**Can't join trip?**
- Verify share code is correct (8 characters)
- Both users must be logged in
- Trip must not be completed/cancelled

## Advanced Testing with GPX

For realistic route simulation, create a GPX file:

```xml
<?xml version="1.0"?>
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="37.7749" lon="-122.4194"><time>2026-04-09T10:00:00Z</time></trkpt>
      <trkpt lat="37.5000" lon="-122.0000"><time>2026-04-09T10:30:00Z</time></trkpt>
      <trkpt lat="37.0000" lon="-121.5000"><time>2026-04-09T11:00:00Z</time></trkpt>
      <trkpt lat="36.5000" lon="-120.5000"><time>2026-04-09T11:30:00Z</time></trkpt>
      <trkpt lat="35.5000" lon="-119.5000"><time>2026-04-09T12:00:00Z</time></trkpt>
      <trkpt lat="34.0522" lon="-118.2437"><time>2026-04-09T12:30:00Z</time></trkpt>
    </trkseg>
  </trk>
</gpx>
```

Use in simulator:
```bash
xcrun simctl location DEVICE_ID load route.gpx
```
