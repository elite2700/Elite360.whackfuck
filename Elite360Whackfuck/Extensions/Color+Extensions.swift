import SwiftUI

extension Color {
    static let elite = EliteColors()
}

struct EliteColors {
    let primary = Color.green
    let background = Color(.systemGroupedBackground)
    let cardBackground = Color(.secondarySystemGroupedBackground)
    let accent = Color(red: 0.2, green: 0.8, blue: 0.0)
    let premium = Color.yellow
    let danger = Color.red
    let money = Color.orange

    func scoreColor(strokes: Int, par: Int) -> Color {
        let diff = strokes - par
        switch diff {
        case ...(-2): return .yellow   // Eagle or better
        case -1: return .red           // Birdie
        case 0: return .primary        // Par
        case 1: return .blue           // Bogey
        default: return .purple        // Double+
        }
    }
}
