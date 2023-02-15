import ComposableArchitecture
import SwiftUI

public struct MenuBarView: View {
  let store: StoreOf<MenuBar>

  public init(store: StoreOf<MenuBar>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: \.user) { viewStore in
      if let recording = viewStore.state?.recordingKeystrokes {
        Text("connected recording: \(recording ? "true" : "false")")
          .padding(20)
      } else {
        Group {
          Text("not connected")
          Button("connect") {
            viewStore.send(.fakeConnect)
          }
        }
        .padding(20)
      }
    }
  }
}

struct SwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    MenuBarView(store: .init(initialState: .init(), reducer: MenuBar()))
      .previewDisplayName("Not connected")
    MenuBarView(store: .init(initialState: .init(), reducer: MenuBar()))
      .previewDisplayName("Connected")
  }
}
