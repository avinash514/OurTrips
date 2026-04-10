//
//  RoadTrip.swift
//  OurTrips
//
//  Created by Avinash Dimmeta on 4/9/26.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class RoadTrip {
    var id: String
    var name: String
    var fromLocation: TripLocation
    var toLocation: TripLocation
    var ownerId: String
    var ownerName: String
    var participants: [TripParticipant]
    var status: TripStatus
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var shareCode: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        fromLocation: TripLocation,
        toLocation: TripLocation,
        ownerId: String,
        ownerName: String,
        shareCode: String = UUID().uuidString.prefix(8).uppercased()
    ) {
        self.id = id
        self.name = name
        self.fromLocation = fromLocation
        self.toLocation = toLocation
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.participants = [TripParticipant(userId: ownerId, userName: ownerName, isOwner: true)]
        self.status = .planned
        self.createdAt = Date()
        self.shareCode = String(shareCode)
    }
}

enum TripStatus: String, Codable {
    case planned = "planned"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct TripLocation: Codable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct TripParticipant: Codable, Identifiable {
    var id: String = UUID().uuidString
    var userId: String
    var userName: String
    var isOwner: Bool
    var joinedAt: Date = Date()
    var currentLocation: ParticipantLocation?
    var lastUpdated: Date?
    
    mutating func updateLocation(latitude: Double, longitude: Double) {
        self.currentLocation = ParticipantLocation(latitude: latitude, longitude: longitude)
        self.lastUpdated = Date()
    }
}

struct ParticipantLocation: Codable {
    var latitude: Double
    var longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
