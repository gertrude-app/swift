import Shared
import SwiftUI

struct MenuBarDropdown: View, StoreView {
  @EnvironmentObject var store: AppStore
  var filterRunning: Bool { store.state.filterStatus == .installedAndRunning }
  var recordingKeystrokes: Bool { store.state.monitoring.keyloggingEnabled }
  var recordingScreen: Bool { store.state.monitoring.screenshotsEnabled }
  var filterState: FilterState { store.state.filterState }

  func DropdownDivider() -> some View {
    Divider()
      .background(Color(hex: darkMode ? 0x333333 : 0xAAAAAA))
      .padding(x: 5, y: 8)
  }

  func Connect() -> some View {
    MenuItem(
      text: "Connect to a User",
      onClick: { store.send(.initialConnectToUserClicked) },
      enabled: true,
      image: "desktopcomputer",
      darkMode: darkMode
    )
    .padding()
    .infinite()
  }

  func FilterLine() -> some View {
    HStack {
      Text("Internet filter:")
      Spacer()
      if !filterRunning || filterState == .suspended {
        Text(filterState == .suspended ? "Resume" : "Turn On")
          .textCase(.uppercase)
          .font(.system(size: 10))
          .padding(x: 7, y: 3)
          .foregroundColor(.white)
          .background(Color.gray)
          .cornerRadius(8)
          .opacity(0.7)
          .onTapGesture { store.send(.menuDropdownEnableFilterClicked) }
      }
      FilterStatePill(filterState: filterState)
    }
    .padding(x: 7)
  }

  func Items() -> some View {
    Group {
      MenuItem(
        text: "View network traffic",
        onClick: { store.send(.menuDropdownViewRequestsClicked) },
        enabled: filterRunning,
        image: "antenna.radiowaves.left.and.right",
        darkMode: darkMode
      )

      if filterRunning {
        MenuItem(
          text: "Disable filter temporarily",
          onClick: { store.send(.menuDropdownDisableFilterTemporarilyClicked) },
          enabled: filterState == .on,
          image: "clock.arrow.circlepath",
          darkMode: darkMode
        )
      }

      MenuItem(
        text: "Refresh rules",
        onClick: { store.send(.userInitiatedRefreshRules) },
        enabled: true,
        image: "arrow.clockwise",
        darkMode: darkMode
      )

      MenuItem(
        text: "Administrate",
        onClick: {
          Auth.challengeAdmin { isAdmin in
            if isAdmin {
              store.send(.menuDropdownAdministrateClicked)
            }
          }
        },
        enabled: true,
        image: "gearshape",
        darkMode: darkMode
      )
    }
  }

  var body: some View {
    if store.state.userToken == nil {
      Connect()
    } else {
      VStack(alignment: .leading, spacing: 3) {
        FilterLine()

        if filterState == .suspended {
          HStack {
            Spacer()
            Text("Resuming \(store.state.filterSuspension?.relativeExpiration ?? "soon")...")
              .italic()
              .opacity(0.70)
              .font(.system(size: 10))
              .padding(x: 7)
              .padding(top: 6)
            Spacer()
          }
        }

        DropdownDivider()

        Items()

        if recordingScreen || recordingKeystrokes {
          DropdownDivider()
        }

        if recordingKeystrokes {
          HStack {
            Image(systemName: "keyboard").foregroundColor(.secondary)
            Text("Gertrude is recording your keystrokes")
              .foregroundColor(.secondary)
              .italic()
          }.padding(left: 8).padding(bottom: 6)
        }

        if recordingScreen {
          HStack {
            Image(systemName: "binoculars").foregroundColor(.secondary)
            Text("Gertrude is recording your screen")
              .foregroundColor(.secondary)
              .italic()
          }.padding(left: 8)
        }

        Spacer()
      }
      .padding(top: 12, right: 5, bottom: 0, left: 5)
      .infinite()
    }
  }
}

struct MenuItem: View {
  var text: String
  var onClick: Dispatch
  var enabled: Bool
  var image: String?
  var darkMode: Bool

  @State private var hovered = false

  var body: some View {
    HStack {
      if let image = image {
        Image(systemName: image)
          .resizable()
          .scaledToFit()
          .frame(width: 14, height: 14)
          .opacity(enabled ? 1 : 0.5)
      }
      Text("\(text)...").foregroundColor(enabled ? .primary : .secondary)
      Spacer()
    }
    .padding(x: 10, y: 4)
    .background(Color(hex: darkMode ? 0x222222 : 0x999999, alpha: hovered && enabled ? 1 : 0))
    .cornerRadius(4)
    .onHover { over in
      hovered = over
    }
    .onTapGesture {
      if enabled {
        hovered = false
        onClick()
      }
    }
  }
}

extension MenuBarDropdown {
  static func dimensions(
    connected: Bool,
    filterRunning: Bool,
    recordingKeystrokes: Bool,
    recordingScreen: Bool,
    filterDisabled: Bool
  ) -> (width: CGFloat, height: CGFloat) {
    var dims: (width: CGFloat, height: CGFloat) = (235, 50)
    if !connected {
      return dims
    }

    dims.width += 65
    switch (recordingScreen, recordingKeystrokes) {
    case (true, true):
      dims.height = 172
    case (true, false), (false, true):
      dims.height = 148
    case(false, false):
      dims.height = 106
    }

    dims.height += 28

    if filterRunning {
      dims.height += 28
    }

    if filterDisabled {
      dims.height += 26
    }

    return dims
  }

  static func dimensions(from store: AppStore) -> (width: CGFloat, height: CGFloat) {
    dimensions(
      connected: store.state.userToken != nil,
      filterRunning: store.state.filterStatus == .installedAndRunning,
      recordingKeystrokes: store.state.monitoring.keyloggingEnabled,
      recordingScreen: store.state.monitoring.screenshotsEnabled,
      filterDisabled: store.state.filterSuspension?.isActive == true
    )
  }

  func startFilter() {
    store.send(.startFilter)
  }

  func stopFilter() {
    Auth.challengeAdmin { isAdmin in
      if isAdmin {
        store.send(.stopFilter)
      }
    }
  }
}

struct MenuBarDropdown_Previews: PreviewProvider, GertrudeProvider {
  static var colorScheme: ColorScheme = .light
  static var initializeState: StateCustomizer? = { state in
    state.userToken = UUID()
    state.filterStatus = .installedAndRunning
  }

  static var cases: [(inout AppState) -> Void] = [
    { state in
      state.filterStatus = .installedAndRunning
    },
    { state in
      state.filterStatus = .installedAndRunning
      state.filterSuspension = .init(scope: .unrestricted, duration: 360)
    },
    { state in
      state.filterStatus = .notInstalled
    },
    { state in
      state.monitoring.screenshotsEnabled = true
    },
    { state in
      state.monitoring.keyloggingEnabled = true
    },
    { state in
      state.monitoring.keyloggingEnabled = true
      state.monitoring.screenshotsEnabled = true
    },
    { state in
      state.userToken = nil
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) { preview in
      let (width, height) = MenuBarDropdown.dimensions(from: preview.store)
      MenuBarDropdown()
        .background(Color(hex: 0xC4C0C0)) // sorta close to how real popover renders
        .store(preview)
        .frame(width: width, height: height)
    }
  }
}
