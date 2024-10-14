import ComposableArchitecture
import Foundation
import SwiftUI

struct PreReqs: View {
  var store: StoreOf<AppReducer>

  var body: some View {
    VStack(spacing: 20) {
      Text("In order to safely use Gertrude")
      VStack(alignment: .leading) {
        Text("- the \(self.deviceType) user must be logged into iCloud")
        Text("- the \(self.deviceType) user must be under 18")
        Text("- the \(self.deviceType) user must be part of an Apple Family")
        Text("- the \(self.deviceType) user must be restricted from deleting apps")
      }.font(.footnote)
      Button("Start authorization") {
        self.store.send(.startAuthorizationTapped)
      }
    }
  }
}

#Preview {
  PreReqs(store: Store(initialState: .init(), reducer: {}))
}
