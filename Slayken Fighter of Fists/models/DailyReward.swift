//
//  DailyReward.swift
//

import Foundation

struct DailyReward: Identifiable {
    let id = UUID().uuidString
    let day: Int
    let title: String
    let coins: Int?
    let crystals: Int?
}
