//
//  PrizePantryActivityAttributes.swift
//  prizepantry
//
//  Created by Shawn Hulme on 1/7/26.
//


// PrizePantryActivityAttributes.swift
import ActivityKit
import SwiftUI

struct PrizePantryActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // The end time for the countdown
        var endTime: Date
    }
    
    // Fixed information (like the child's name)
    var name: String
}