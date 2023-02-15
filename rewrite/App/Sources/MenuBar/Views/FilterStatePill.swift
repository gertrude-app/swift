import Shared
import SwiftUI

struct FilterStatePill: View {
  var filterState: FilterState
  var body: some View {
    Text(filterState.rawValue.uppercased())
      .font(.system(size: 10))
      .padding(x: 9, y: 3)
      .foregroundColor(.white)
      .background(filterState.bgColor)
      .cornerRadius(8)
  }
}

extension FilterState {
  var bgColor: Color {
    switch self {
    case .on:
      return Color(hex: 0x3CAD26)
    case .off:
      return Color(hex: 0xB32222)
    case .suspended:
      return Color(hex: 0xEB881E)
    }
  }
}

@MainActor struct FilterStatePill_Previews: PreviewProvider {
  static var previews: some View {
    FilterStatePill(filterState: .off).padding()
    FilterStatePill(filterState: .on).padding()
    FilterStatePill(filterState: .suspended).padding()
  }
}
