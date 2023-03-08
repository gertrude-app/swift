import ComposableArchitecture
import SwiftUI

public struct MenuBarView: View {
  let store: StoreOf<MenuBar>

  public init(store: StoreOf<MenuBar>) {
    self.store = store
  }

  public var body: some View {
    Text("goodbye, swiftui")
  }
}
