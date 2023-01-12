import SwiftUI

extension Color {
  init(hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 08) & 0xFF) / 255,
      blue: Double((hex >> 00) & 0xFF) / 255,
      opacity: alpha
    )
  }

  static let darkModeRed = Color(hex: 0xB32222)
  static let lightModeRed = Color.red
  static let darkModeGreen = Color(hex: 0x3A9129)
  static let lightModeGreen = Color.green
  static let brandPurple = Color(hex: 0x8B5CF6)
  static let brandFuchsia = Color(hex: 0xD946EF)
  static let warningOrange = Color(hex: 0xFF7900)
}
