//
//  GiftItem.swift
//

import Foundation

struct GiftItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let image: String
    let reward: Reward

    struct Reward {
        let coins: Int?
        let crystals: Int?
    }
}
