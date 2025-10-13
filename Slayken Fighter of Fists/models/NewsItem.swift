import Foundation

struct NewsItem: Identifiable, Codable {
    let id: Int
    let title: String
    let date: String
    let description: String
    let image: String
}
