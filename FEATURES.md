# OurTrips - Road Trip Features

## Overview
OurTrips is now a collaborative road trip tracking application where users can create trips, share them with friends, and track everyone's location in real-time.

## Key Features

### 1. **Create Road Trip**
- Users can create a road trip by specifying:
  - Trip name
  - Starting location (search with auto-complete)
  - Destination location (search with auto-complete)
- Each trip gets a unique 8-character share code
- Trip owner has full control over the trip

### 2. **Share Trip**
- Trip owner can share the trip via:
  - **Share Code**: 8-character code that friends can manually enter
  - **Share Link**: Deep link (`ourtrips://join/[CODE]`) that can be shared via messages, email, etc.
- Share sheet includes:
  - Trip name
  - From/To locations
  - Share code prominently displayed
  - Copy code button
  - Share link button with iOS share sheet

### 3. **Join Trip**
- Users can join existing trips by:
  - Entering the share code manually
  - Clicking on a shared link (deep linking)
- System validates:
  - Trip exists
  - User not already a participant
- Automatic addition to trip participants list

### 4. **Trip Management**
Trip owners can:
- **Start Trip**: Activates live tracking for all participants
- **End Trip**: Completes the trip and stops tracking
- View all participants
- See trip status (Planned, Active, Completed, Cancelled)

### 5. **Live Tracking**
When a trip is active:
- **Real-time Location Sharing**: All participants' locations are updated every 5 seconds
- **Interactive Map** showing:
  - Starting point (green marker)
  - Destination (red marker)
  - All participants (color-coded markers):
    - Blue: Current user
    - Purple: Other participants
    - Star icon: Trip owner
    - Car icon: Regular participants
- **Participants List Overlay**: Shows who's currently online/sharing location
- **Auto-center**: Button to zoom to show all participants
- **Map Controls**: User location button, compass, scale view

### 6. **Trip Statuses**
- **Planned** (Blue): Trip created but not started
- **Active** (Green): Trip in progress with live tracking
- **Completed** (Gray): Trip finished
- **Cancelled** (Red): Trip cancelled

### 7. **Trips List**
- Shows all trips user is participating in
- Displays:
  - Trip name
  - From → To locations
  - Number of participants
  - Status badge
  - Owner indicator (star)
  - Time since creation
- Options to:
  - Create new trip
  - Join existing trip
  - Delete trips (swipe to delete)

## User Flows

### Creating and Sharing a Trip
1. User logs in
2. Goes to Trips tab
3. Taps "+" → "Create Trip"
4. Enters trip name and searches for from/to locations
5. Taps "Create"
6. In trip details, taps "Share Trip"
7. Shares code or link with friends

### Joining a Trip
1. Friend receives share code or link
2. Opens app and logs in
3. Taps "+" → "Join Trip"
4. Enters share code
5. Taps "Join Trip"
6. Now part of the trip!

### Starting a Trip
1. Trip owner opens trip details
2. Taps "Start Trip"
3. Confirms in dialog
4. Trip status changes to "Active"
5. All participants can now view live tracking

### Live Tracking
1. Any participant taps "View Live Tracking"
2. Map opens showing:
   - Route from start to destination
   - All participants' real-time locations
   - Participant list showing online status
3. App updates locations every 5 seconds
4. Users can follow along the journey together

## Technical Architecture

### Models
- **RoadTrip**: Main trip model with SwiftData
  - Contains from/to locations, participants, status, dates
  - Share code for joining
  - Owner information
  
- **TripParticipant**: Individual participant data
  - User ID, name, join date
  - Current location (updated in real-time)
  - Last updated timestamp
  
- **TripLocation**: Location data with coordinates
  - Name, address, lat/long
  - Converts to CLLocationCoordinate2D

### Services
- **TripSharingService**: Handles URL generation and parsing
- **LocationManager**: Manages real-time location updates
- **AuthManager**: User authentication and management

### Views
- **RoadTripsListView**: Main trips listing
- **CreateTripView**: Trip creation with location search
- **RoadTripDetailView**: Trip details and management
- **ShareTripView**: Beautiful share code presentation
- **JoinTripView**: Join via share code
- **LiveTrackingView**: Real-time map with all participants

## Permissions Required
- **Location Services**: For real-time tracking during active trips
- Must be granted for live tracking to work

## Privacy & Security
- Location sharing only active during trip
- Owner controls when trip starts/stops
- Location updates stop when trip ends
- Each user sees only participants in their trips

## Future Enhancements (Ideas)
- Push notifications when trip starts
- Chat feature for trip participants
- Route optimization suggestions
- Photo sharing during trip
- Trip history and statistics
- Estimated arrival times
- Gas station/rest stop suggestions
