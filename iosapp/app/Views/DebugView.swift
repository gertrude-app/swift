import ComposableArchitecture
import Dependencies
import LibApp
import SwiftUI

struct DebugView: View {
  @Bindable var store: StoreOf<Debug>

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Gradient(colors: [.violet300, .violet100]))
        .ignoresSafeArea()
      VStack {
        Spacer()
        if let vendorId = store.state.vendorId {
          Text(vendorId.uuidString)
            .font(.system(.caption, design: .monospaced))
            .foregroundColor(.secondary)
        } else {
          ProgressView()
        }
        Spacer()
      }
      .padding()
    }
  }
}

#Preview {
  DebugView(store: .init(initialState: .init()) {
    Debug()
  })
}
