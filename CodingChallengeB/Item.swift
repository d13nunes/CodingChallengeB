//
//  Item.swift
//  CodingChallengeB
//
//  Created by Diogo Nunes on 17/06/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
