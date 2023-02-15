import ComposableArchitecture
import SwiftUI

public struct MenuBarView: View {
  let store: StoreOf<MenuBar>

  public init(store: StoreOf<MenuBar>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: \.user) { viewStore in
      if let user = viewStore.state {
        VStack(alignment: .leading, spacing: 3) {
          FilterLine(viewStore: viewStore)
          if user.filterState == .suspended {
            HStack {
              Spacer()
              Text("Resuming \(user.filterSuspension?.relativeExpiration ?? "soon")...")
                .italic()
                .opacity(0.70)
                .font(.system(size: 10))
                .padding(x: 7)
                .padding(top: 6)
              Spacer()
            }
          }

          DropdownDivider()

          Group {
            TextItemView(
              text: "View network traffic",
              onClick: { /* store.send(.menuDropdownViewRequestsClicked) */ },
              enabled: user.filterRunning,
              image: "antenna.radiowaves.left.and.right"
            )

            if user.filterRunning {
              TextItemView(
                text: "Disable filter temporarily",
                onClick: { /* store.send(.menuDropdownDisableFilterTemporarilyClicked) */ },
                enabled: user.filterState == .on,
                image: "clock.arrow.circlepath"
              )
            }

            TextItemView(
              text: "Refresh rules",
              onClick: { /* store.send(.userInitiatedRefreshRules) */ },
              enabled: true,
              image: "arrow.clockwise"
            )

            TextItemView(
              text: "Administrate",
              onClick: { /* if isAdmin { store.send(.menuDropdownAdministrateClicked) } */ },
              enabled: true,
              image: "gearshape"
            )
          }

          if user.recordingScreen || user.recordingKeystrokes {
            DropdownDivider()

            Group {
              
              if user.recordingKeystrokes {
                HStack {
                  if #available(macOS 11, *) {
                    Image(systemName: "keyboard").foregroundColor(.secondary)
                  } else {
                    EmptyView()
                  }
                  Text("Gertrude is recording your keystrokes")
                    .foregroundColor(.secondary)
                    .italic()
                }
                .padding(left: 0)
                .padding(bottom: 6)
              }
              
              if user.recordingScreen {
                HStack {
                  if #available(macOS 11, *) {
                    Image(systemName: "binoculars").foregroundColor(.secondary)
                  } else {
                    EmptyView()
                  }
                  Text("Gertrude is recording your screen")
                    .foregroundColor(.secondary)
                    .italic()
                }
                .padding(left: 8)
              }
            }
            .offset(y: -7)
          }

          Spacer()
        }
        .padding(top: 12, right: 5, bottom: 0, left: 5)
        .infinite()

      } else {
        TextItemView(
          text: "Connect to a User",
          onClick: { viewStore.send(.fakeConnect) },
          enabled: true,
          image: "desktopcomputer"
        )
        .padding()
      }
    }
  }
}

struct FilterLine: View {
  @ObservedObject var viewStore: ViewStore<MenuBar.State.User?, MenuBar.Action>

  var body: some View {
    HStack {
      Text("Internet filter:")
      Spacer()
      if viewStore.state?.filterRunning == false || viewStore.state?.filterState == .suspended {
        Text(viewStore.state?.filterState == .suspended ? "RESUME" : "TURN ON")
          .font(.system(size: 10))
          .padding(x: 7, y: 3)
          .foregroundColor(.white)
          .background(Color.gray)
          .cornerRadius(8)
          .opacity(0.7)
          .onTapGesture { /* store.send(.menuDropdownEnableFilterClicked) */ }
      }
      FilterStatePill(filterState: viewStore.state?.filterState ?? .off)
    }
    .padding(x: 7)
  }
}

struct DropdownDivider: View {
  var body: some View {
    Divider()
      .background(Color(hex: 0xAAAAAA))
      .padding(x: 5, y: 8)
  }
}

// previews

@MainActor struct MenuBarView_Previews: PreviewProvider {
  struct Preview {
    var name: String
    var state: MenuBar.State
    var width: CGFloat { state.viewDimensions.width }
    var height: CGFloat { state.viewDimensions.height }
  }

  static var cases = [
    Preview(name: "Not connected", state: .init()),
    Preview(name: "Connected", state: .init(user: .init())),
    Preview(name: "All on", state: .init(user: .init(filterRunning: true, recordingKeystrokes: true, recordingScreen: true, filterState: .on, filterSuspension: nil))),
  ]

  static var previews: some View {
    MenuBarView(store: .init(initialState: cases[0].state, reducer: MenuBar()))
      .previewDisplayName(cases[0].name)
      .frame(width: cases[0].width, height: cases[0].height)
    MenuBarView(store: .init(initialState: cases[1].state, reducer: MenuBar()))
      .previewDisplayName(cases[1].name)
      .frame(width: cases[1].width, height: cases[1].height)
    MenuBarView(store: .init(initialState: cases[2].state, reducer: MenuBar()))
      .previewDisplayName(cases[2].name)
      .frame(width: cases[2].width, height: cases[2].height)
  }
}
