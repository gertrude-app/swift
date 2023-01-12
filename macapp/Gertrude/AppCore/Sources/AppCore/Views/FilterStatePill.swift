import Shared
import SwiftUI

struct FilterStatePill: View {
  var filterState: FilterState
  var body: some View {
    Text(filterState.rawValue)
      .textCase(.uppercase)
      .font(.system(size: 10))
      .padding(x: 9, y: 3)
      .foregroundColor(.white)
      .background(filterState.bgColor)
      .cornerRadius(8)
  }
}

struct FilterStatePill_Previews: PreviewProvider {
  static var previews: some View {
    FilterStatePill(filterState: .off).padding()
    FilterStatePill(filterState: .on).padding()
    FilterStatePill(filterState: .suspended).padding()
  }
}
