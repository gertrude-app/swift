import Cocoa
import Shared
import LaunchAtLogin
import SharedCore
import UserNotifications

public class App: NSObject, NSApplicationDelegate, AppEventReceiver {
  static var shared: App!
  let store = AppStore(initialState: .init(), reducer: appReducer, environment: .live)
  private var plugins: [Plugin] = []
  private var allPluginsLoaded = false
  private var bufferedEvents: [AppEvent] = []

  // @TODO: maybe this belongs in a plugin?, probably better in a Current.X
  var appDescriptorFactory = AppDescriptorFactory(appIdManifest: AppIdManifest())

  public func applicationDidFinishLaunching(_ notification: Notification) {
    App.shared = self

    Current.appVersion = Bundle.main.version

    plugins = [
      LoggingPlugin(store: store),
      FilterPlugin(store: store),
      KeyloggingPlugin(store: store),
      ScreenshotsPlugin(store: store),
      MenuBarPlugin(store: store),
      ColorSchemePlugin(store: store),
      AdminWindowPlugin(store: store),
      RequestsWindowPlugin(store: store),
      FilterSuspensionPlugin(store: store),
      WebSocketPlugin(store: store),
      NotificationsPlugin(store: store),
      AutoUpdatePlugin(store: store),
      BackgroundRefreshPlugin(store: store),
      AccountStatusPlugin(store: store),
      HoneycombPlugin(store: store),
      MigrationPlugin(store: store),
    ]

    allPluginsLoaded = true
    store.send(.emitAppEvent(.allPluginsAdded))
    bufferedEvents.forEach(notify(event:))

    if !LaunchAtLogin.isEnabled, !isDev() {
      log(.notice("enabling launch at login"))
      LaunchAtLogin.isEnabled = true
    }

    // also possibly interesting: NSWorkspace.screensDidSleepNotification

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(App.receiveSleep(_:)),
      name: NSWorkspace.willSleepNotification,
      object: nil
    )

    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(App.receiveWakeup(_:)),
      name: NSWorkspace.didWakeNotification,
      object: nil
    )
  }

  @objc func receiveSleep(_ notification: Notification) {
    notify(event: .appWillSleep)
  }

  @objc func receiveWakeup(_ notification: Notification) {
    notify(event: .appDidWake)
  }

  public func applicationWillTerminate(_ notification: Notification) {
    plugins.reversed().forEach { $0.onTerminate() }
  }

  func notify(event: AppEvent) {
    guard allPluginsLoaded else {
      bufferedEvents.append(event)
      return
    }
    plugins.forEach { $0.respond(to: event) }
  }
}

typealias Unit = SharedCore.Unit

var Current = Env.live
