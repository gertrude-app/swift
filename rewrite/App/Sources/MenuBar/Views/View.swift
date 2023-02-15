import SwiftUI

extension View {
  func padding(
    top: CGFloat? = nil,
    right: CGFloat? = nil,
    bottom: CGFloat? = nil,
    left: CGFloat? = nil
  ) -> some View {
    padding(.init(
      top: top ?? 10,
      leading: left ?? 10,
      bottom: bottom ?? 10,
      trailing: right ?? 10
    ))
  }

  func padding(left: CGFloat, right: CGFloat) -> some View {
    padding(.leading, left).padding(.trailing, right)
  }

  func padding(left: CGFloat) -> some View {
    padding(.leading, left)
  }

  func padding(right: CGFloat) -> some View {
    padding(.trailing, right)
  }

  func padding(top: CGFloat, bottom: CGFloat) -> some View {
    padding(.top, top).padding(.bottom, bottom)
  }

  func padding(x: CGFloat) -> some View {
    padding(.leading, x).padding(.trailing, x)
  }

  func padding(y: CGFloat) -> some View {
    padding(.top, y).padding(.bottom, y)
  }

  func padding(x: CGFloat, y: CGFloat) -> some View {
    padding(x: x).padding(y: y)
  }
  
  func infinite() -> some View {
    frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

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
}
