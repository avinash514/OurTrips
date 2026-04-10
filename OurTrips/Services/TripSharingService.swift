//
//  TripSharingService.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import Foundation
import UIKit

class TripSharingService {
    static let shared = TripSharingService()
    
    private let baseURL = "ourtrips://join/"
    
    // Use both file storage AND pasteboard for better cross-simulator sharing
    private var sharedTripsFileURL: URL {
        let filePath = "/tmp/ourtrips_shared_trips.json"
        let fileURL = URL(fileURLWithPath: filePath)
        print("🔗 Shared trips file: \(fileURL.path)")
        return fileURL
    }
    
    func generateShareURL(for trip: RoadTrip) -> URL? {
        let urlString = "\(baseURL)\(trip.shareCode)"
        return URL(string: urlString)
    }
    
    func generateShareMessage(for trip: RoadTrip) -> String {
        let url = generateShareURL(for: trip)?.absoluteString ?? ""
        return """
        Join my road trip on OurTrips! 🚗
        
        Trip: \(trip.name)
        From: \(trip.fromLocation.name)
        To: \(trip.toLocation.name)
        
        Click to join: \(url)
        Or use share code: \(trip.shareCode)
        """
    }
    
    func parseShareCode(from url: URL) -> String? {
        if url.scheme == "ourtrips", url.host == "join" {
            return url.pathComponents.last
        }
        return nil
    }
    
    // Store trip info for sharing across devices (testing workaround using shared file + clipboard)
    func shareTrip(_ trip: RoadTrip) {
        // Convert participants to shareable format
        let participantsData: [[String: Any]] = trip.participants.map { participant in
            var data: [String: Any] = [
                "userId": participant.userId,
                "userName": participant.userName,
                "isOwner": participant.isOwner
            ]
            
            if let location = participant.currentLocation {
                data["latitude"] = location.latitude
                data["longitude"] = location.longitude
            }
            
            if let lastUpdated = participant.lastUpdated {
                data["lastUpdated"] = lastUpdated.timeIntervalSince1970
            }
            
            return data
        }
        
        let tripData: [String: Any] = [
            "id": trip.id,
            "name": trip.name,
            "shareCode": trip.shareCode,
            "ownerId": trip.ownerId,
            "ownerName": trip.ownerName,
            "fromLocationName": trip.fromLocation.name,
            "fromLocationAddress": trip.fromLocation.address,
            "fromLocationLat": trip.fromLocation.latitude,
            "fromLocationLon": trip.fromLocation.longitude,
            "toLocationName": trip.toLocation.name,
            "toLocationAddress": trip.toLocation.address,
            "toLocationLat": trip.toLocation.latitude,
            "toLocationLon": trip.toLocation.longitude,
            "status": trip.status.rawValue,
            "createdAt": trip.createdAt.timeIntervalSince1970,
            "startedAt": trip.startedAt?.timeIntervalSince1970 ?? 0,
            "completedAt": trip.completedAt?.timeIntervalSince1970 ?? 0,
            "participants": participantsData
        ]
        
        // Save to file
        var sharedTrips = getSharedTrips()
        sharedTrips[trip.shareCode] = tripData
        saveSharedTrips(sharedTrips)
        
        // Also save to clipboard for cross-simulator testing
        saveToPasteboard(tripData: tripData, shareCode: trip.shareCode)
        
        print("📝 Shared trip '\(trip.name)' with code: \(trip.shareCode) - Status: \(trip.status.rawValue)")
        print("👥 Synced \(trip.participants.count) participants")
        print("📂 Saved to file: \(sharedTripsFileURL.path)")
        print("📋 Saved to clipboard for cross-device sharing")
    }
    
    private func saveToPasteboard(tripData: [String: Any], shareCode: String) {
        let pasteboardKey = "OurTrips_\(shareCode)"
        if let jsonData = try? JSONSerialization.data(withJSONObject: tripData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            UIPasteboard.general.string = "\(pasteboardKey)|\(jsonString)"
            print("✅ Trip data saved to clipboard with key: \(pasteboardKey)")
        }
    }
    
    private func getFromPasteboard(shareCode: String) -> [String: Any]? {
        guard let pasteboardContent = UIPasteboard.general.string else {
            print("📋 No clipboard content")
            return nil
        }
        
        let pasteboardKey = "OurTrips_\(shareCode)"
        let components = pasteboardContent.split(separator: "|", maxSplits: 1)
        
        guard components.count == 2,
              components[0] == pasteboardKey,
              let jsonData = String(components[1]).data(using: .utf8),
              let tripData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("📋 Clipboard doesn't contain trip data for code: \(shareCode)")
            return nil
        }
        
        print("✅ Found trip data in clipboard for code: \(shareCode)")
        return tripData
    }
    
    func getSharedTrip(shareCode: String) -> [String: Any]? {
        print("🔍 Looking for trip with code: \(shareCode)")
        
        // First, try clipboard (most reliable for cross-simulator testing)
        if let tripFromClipboard = getFromPasteboard(shareCode: shareCode) {
            print("✅ Found trip in clipboard!")
            return tripFromClipboard
        }
        
        // Fallback to file storage
        let sharedTrips = getSharedTrips()
        print("📂 Available trips in file: \(sharedTrips.keys.joined(separator: ", "))")
        
        if let trip = sharedTrips[shareCode] as? [String: Any] {
            print("✅ Found trip in file!")
            return trip
        }
        
        print("❌ Trip not found in clipboard or file")
        return nil
    }
    
    private func getSharedTrips() -> [String: Any] {
        guard FileManager.default.fileExists(atPath: sharedTripsFileURL.path) else {
            print("📂 No shared trips file found at: \(sharedTripsFileURL.path)")
            return [:]
        }
        
        do {
            let data = try Data(contentsOf: sharedTripsFileURL)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ Loaded \(json.count) shared trips from file")
                return json
            }
        } catch {
            print("❌ Error reading shared trips: \(error.localizedDescription)")
        }
        
        return [:]
    }
    
    private func saveSharedTrips(_ trips: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: trips, options: .prettyPrinted)
            try data.write(to: sharedTripsFileURL, options: .atomic)
            print("✅ Successfully saved shared trips to file")
        } catch {
            print("❌ Error saving shared trips: \(error.localizedDescription)")
        }
    }
    
    func removeSharedTrip(shareCode: String) {
        var sharedTrips = getSharedTrips()
        sharedTrips.removeValue(forKey: shareCode)
        saveSharedTrips(sharedTrips)
    }
}
