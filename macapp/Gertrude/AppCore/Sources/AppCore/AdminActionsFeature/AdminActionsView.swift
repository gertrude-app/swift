import Gertie
import SharedCore
import SwiftUI

struct ReleaseItem: Decodable { var version: String, channel: ReleaseChannel }
extension ReleaseItem: Hashable {}

struct AdminActionsView: View, StoreView {
  @EnvironmentObject var store: AppStore
  private typealias SuspensionType = AdminWindowState.ActionsState.FilterSuspension.SuspensionType
  private typealias DebugLength = AdminWindowState.ActionsState.DebugSessionLength
  private var rowHeight: CGFloat = 43
  var state: AdminWindowState.ActionsState { store.state.adminWindow.actionsState }
  var filterState: FilterState { store.state.filterState }

  private var advancedViewNumRequiredClicks = isDev() ? 5 : 20
  @State private var numTimesHiddenTargetClicked = 0

  var body: some View {
    AdminWindowSubScreen(section: .actions) {
      if numTimesHiddenTargetClicked >= advancedViewNumRequiredClicks {
        AdvancedActionsView(
          send: { store.send($0) },
          onGoBack: { numTimesHiddenTargetClicked = 0 }
        )
      } else {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Group {
              switch filterState {
              case .on:
                ProtectedButton("Stop the filter") { store.send(.stopFilter) }
              case .off:
                Button("Start the filter") {
                  store.send(.startFilter)
                }
              case .suspended:
                Button("Resume the filter") {
                  store.send(.adminActionsResumeFilterClicked)
                }
              }
            }
            Text("Filter is").subtle().onTapGesture { numTimesHiddenTargetClicked += 1 }
            FilterStatePill(filterState: store.state.filterState).offset(x: -3)
            Spacer()
          }.frame(height: rowHeight)

          HStack {
            ProtectedButton("Suspend the filter", disabled: filterState != .on) {
              store.send(.adminActions(.filterSuspensionStarted))
            }
            switch filterState {
            case .on:
              Text("for")
              TextField("", text: store.bind(
                { String(state.filterSuspension.duration.rawValue) },
                { .adminActions(.filterSuspensionDurationChanged(.init(rawValue: .init($0) ?? 5))) }
              )).frame(width: 40)
              Text("minutes")
            case .off:
              Text("Filter is currently not running").subtle()
            case .suspended:
              Text("Filter is already suspended").subtle()
            }
            Spacer()
          }.frame(height: rowHeight)

          HStack {
            Button("Check for updates") {
              store.send(.emitAppEvent(.requestCheckForUpdates))
            }
            Text("or")
            ProtectedButton("Reinstall") {
              store.send(.emitAppEvent(.forceAppUpdate))
            }
            Text("Currently updating to").subtle().padding(left: 4)
            Picker("", selection: store.bind(
              \.autoUpdateReleaseChannel,
              { .adminActions(.autoUpdateReleaseChannelChanged($0)) }
            )) {
              Text("stable").tag(ReleaseChannel.stable)
              Text("beta").tag(ReleaseChannel.beta)
            }
            .frame(width: 80)
            .offset(x: -12)
            Text("versions").subtle()
              .offset(x: -12)
            Spacer()
          }
          .frame(height: rowHeight)

          HStack {
            switch state.screenshot.state {
            case .configuring:
              Button("Take a test screenshot") {
                store.send(.adminActions(.screenshotRequested))
              }
              Text("at")
              TextField("", text: store.bind(
                { String(state.screenshot.size) },
                { .adminActions(.screenshotSizeChanged(.init($0) ?? 1000)) }
              )).frame(width: 60)
              Text("pixels")
            case .beingTaken:
              Submitting("")
            case .failed:
              HStack {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(red)
                Text("An error occured taking the test screenshot, please try again")
                  .foregroundColor(red)
              }
            case .succeeded:
              Button("View screenshot") {
                store.send(.adminActions(.viewScreenshotButtonClicked))
              }
            }
          }
          .frame(height: rowHeight)

          HStack {
            ProtectedButton("Reconnect user") {
              store.send(.deleteUserToken)
            }
            .frame(height: rowHeight)
            if isDev(), store.state.userToken != nil {
              Markdown("`\(store.state.userToken?.lowercased ?? "")`").subtle()
            }
          }

          HStack {
            if !store.state.logging.debugging {
              Button("Send debug data") {
                store.send(.adminActions(.startDebugSessionButtonClicked))
              }
              Picker("for the next", selection: store.bind(
                \.adminWindow.actionsState.debugSessionLength,
                { .adminActions(.debugSessionLengthChanged($0)) }
              )) {
                Text("five minutes").tag(DebugLength.fiveMinutes)
                Text("one hour").tag(DebugLength.oneHour)
                Text("24 hours").tag(DebugLength.oneDay)
              }.frame(width: 200)
            } else {
              Text("Currently sending extra debug data").subtle()
              Button("Stop") {
                store.send(.adminActions(.stopDebugSessionButtonClicked))
              }
            }
            Spacer()
          }.frame(height: rowHeight)

          Group {
            if state.quitting {
              Submitting("quitting...")
            } else {
              ProtectedButton("Quit the app", danger: true) {
                store.send(.adminActions(.quitButtonClicked))
              }
            }
          }
          .frame(height: rowHeight)

          Spacer()
        }
        .padding(left: 15)
      }
      Spacer()
    }
    .onAppear { numTimesHiddenTargetClicked = 0 }
  }
}

struct ProtectedButton: View {
  var text: String
  var disabled: Bool
  var action: () -> Void
  var danger: Bool

  init(_ text: String, disabled: Bool = false, danger: Bool = false, action: @escaping () -> Void) {
    self.text = text
    self.disabled = disabled
    self.action = action
    self.danger = danger
  }

  var body: some View {
    Button(text) {
      Auth.challengeAdmin { isAdmin in
        if isAdmin { action() }
      }
    }
    .disabled(disabled)
    .foregroundColor(disabled ? .gray : danger ? .darkModeRed : nil)
  }
}

struct AdminActionsView_Previews: PreviewProvider, GertrudeProvider {
  static var cases: [StateCustomizer] = [
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedAndRunning
      state.adminWindow.actionsState.screenshot.state = .configuring
    },
    { state in
      state.colorScheme = .light
      state.filterStatus = .installedButNotRunning
      state.adminWindow.actionsState.screenshot.state = .failed
      state.adminWindow.actionsState.quitting = true
    },
    { state in
      state.colorScheme = .dark
      state.filterStatus = .installedAndRunning
      state.filterSuspension = .init(scope: .unrestricted, duration: 500)
      state.adminWindow.actionsState.screenshot.state = .succeeded(URL(string: "/")!)
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      AdminActionsView().store($0).adminPreview()
    }
  }
}
