import SwiftUI

enum SongCardPalette {
    static let count = 8

    static let colors: [Color] = [
        Color(red: 0.89, green: 0.91, blue: 0.40),
        Color(red: 0.70, green: 0.76, blue: 0.98),
        Color(red: 0.96, green: 0.50, blue: 0.33),
        Color(red: 0.53, green: 0.80, blue: 0.95),
        Color(red: 0.55, green: 0.92, blue: 0.65),
        Color(red: 0.98, green: 0.75, blue: 0.45),
        Color(red: 0.18, green: 0.62, blue: 0.58),
        Color(red: 0.95, green: 0.55, blue: 0.72)
    ]

    static func swiftUIColor(at index: Int) -> Color {
        let i = min(max(0, index), colors.count - 1)
        return colors[i]
    }
}
