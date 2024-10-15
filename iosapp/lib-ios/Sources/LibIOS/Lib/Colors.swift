import SwiftUI

let violet100 = Color(hex: "#ede9fe")!
let violet200 = Color(hex: "#ddd6fe")!
let violet300 = Color(hex: "#c4b5fd")!
let violet400 = Color(hex: "#a78bfa")!
let violet500 = Color(hex: "#8b5cf6")!
let violet600 = Color(hex: "#7c3aed")!
let violet700 = Color(hex: "#6d28d9")!
let violet800 = Color(hex: "#5b21b6")!
let violet900 = Color(hex: "#4c1d95")!

let fuschia100 = Color(hex: "#fae8ff")!
let fuchsia200 = Color(hex: "#f5d0fe")!
let fuchsia300 = Color(hex: "#f0abfc")!
let fuchsia400 = Color(hex: "#e879f9")!
let fuchsia500 = Color(hex: "#d946ef")!
let fuchsia600 = Color(hex: "#c026d3")!
let fuchsia700 = Color(hex: "#a21caf")!
let fuchsia800 = Color(hex: "#86198f")!
let fuchsia900 = Color(hex: "#701a75")!

public extension Color {
  init?(hex: String) {
    let r, g, b: Double

    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    switch hexSanitized.count {
    case 3: // RGB
      (r, g, b) = (
        Double((rgb >> 8) & 0xF) / 15.0,
        Double((rgb >> 4) & 0xF) / 15.0,
        Double(rgb & 0xF) / 15.0
      )
    case 6: // RRGGBB
      (r, g, b) = (
        Double((rgb >> 16) & 0xFF) / 255.0,
        Double((rgb >> 8) & 0xFF) / 255.0,
        Double(rgb & 0xFF) / 255.0
      )
    default:
      return nil
    }

    self.init(red: r, green: g, blue: b)
  }
}
