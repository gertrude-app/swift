import SharedCore
import SwiftUI

struct AdvancedActionsView: View {
  @State private var pairqlEndpoint = ""
  @State private var websocketEndpoint = ""
  @State private var appcastEndpoint = ""
  @State private var selectedRelease = ReleaseItem(version: "0.0.0", channel: .stable)
  @State private var releases: [ReleaseItem] = []

  var send: (AppAction) -> Void
  var onGoBack: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Markdown("_Api PairQL_ endpoint override:")
          .frame(width: 185, alignment: .leading)
        TextField("", text: $pairqlEndpoint)
        ProtectedButton("Start") {
          if pairqlEndpoint == "" {
            Current.deviceStorage.delete(.pairQLEndpointOverride)
          } else {
            Current.deviceStorage.set(.pairQLEndpointOverride, pairqlEndpoint)
          }
        }
      }
      HStack {
        Markdown("_Websocket_ endpoint override:")
          .frame(width: 185, alignment: .leading)
        TextField("", text: $websocketEndpoint)
        ProtectedButton("Start") {
          if websocketEndpoint == "" {
            Current.deviceStorage.delete(.websocketEndpointOverride)
          } else {
            Current.deviceStorage.set(.websocketEndpointOverride, websocketEndpoint)
          }
          send(.emitAppEvent(.websocketEndpointChanged))
        }
      }
      HStack {
        Markdown("_Appcast_ endpoint override:")
          .frame(width: 185, alignment: .leading)
        TextField("", text: $appcastEndpoint)
        ProtectedButton("Start") {
          if appcastEndpoint == "" {
            Current.deviceStorage.delete(.appcastEndpointOverride)
          } else {
            Current.deviceStorage.set(.appcastEndpointOverride, appcastEndpoint)
          }
        }
      }
      HStack {
        Markdown("Force auto-update to specific version")
        Picker("", selection: $selectedRelease) {
          ForEach(releases, id: \.version) { release in
            Text("\(release.version) (\(release.channel.rawValue))")
              .tag(release)
          }
        }
        ProtectedButton("Start") {
          send(.emitAppEvent(.forceAutoUpdateToVersion(selectedRelease.version)))
          send(.emitAppEvent(.requestCheckForUpdates))
        }
      }
      .padding(bottom: 18)
      HStack {
        ProtectedButton("Purge all device storage") {
          log(.warn("purge all device storage button clicked"))
          Current.deviceStorage.purgeAll()
          SendToFilter.purgeAllDeviceStorage()
        }
      }
      ProtectedButton("View logs") {
        send(.adminActions(.viewLogsButtonClicked))
      }
      Spacer()
      Button("← Back", action: onGoBack)
    }
    .onAppear {
      pairqlEndpoint = Current.deviceStorage.get(.pairQLEndpointOverride) ?? ""
      websocketEndpoint = Current.deviceStorage.get(.websocketEndpointOverride) ?? ""
      appcastEndpoint = Current.deviceStorage.get(.appcastEndpointOverride) ?? ""
      URLSession.shared.dataTask(with: SharedConstants.RELEASE_ENDPOINT) { data, _, _ in
        guard let data = data else { return }
        if let fetched = try? JSONDecoder().decode([ReleaseItem].self, from: data) {
          releases = fetched.sorted(by: { $0.version > $1.version })
          releases.first.map { selectedRelease = $0 }
        }
      }.resume()
    }
  }
}
