//
//  Models.swift
//  prizepantry
//
//  Created by Shawn Hulme on 12/29/25.
//

import Foundation
import SwiftData

@Model
class Child {
    var name: String
    var tokenBalance: Int
    
    // This creates a relationship: a child can have many prizes
    @Relationship(deleteRule: .cascade)
    var prizes: [Prize] = []
    
    init(name: String, tokenBalance: Int = 0) {
        self.name = name
        self.tokenBalance = tokenBalance
    }
}

@Model
class Prize {
    var title: String
    var tokenCost: Int
    var isRedeemed: Bool
    
    init(title: String, tokenCost: Int, isRedeemed: Bool = false) {
        self.title = title
        self.tokenCost = tokenCost
        self.isRedeemed = isRedeemed
    }
}
