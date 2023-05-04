import Foundation

@testable import App

struct AppWebViews: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    AppviewStore(
      at: "MenuBar/menubar-store.ts",
      generating: [
        .init(MenuBarFeature.State.Connected.FilterState.self),
        .init(MenuBarFeature.State.self, as: "AppState"),
        .init(MenuBarFeature.Action.self, as: "AppEvent"),
      ],
      aliasing: ["filterState": "FilterState"]
    ),
    AppviewStore(
      at: "BlockedRequests/blockedrequests-store.ts",
      generating: [
        .init(BlockedRequestsFeature.State.View.Request.self),
        .init(BlockedRequestsFeature.State.View.self, as: "AppState"),
        .init(BlockedRequestsFeature.Action.View.self, as: "AppEvent"),
      ],
      aliasing: ["requests": "Request[]"]
    ),
    AppviewStore(
      at: "Administrate/administrate-store.ts",
      generating: [
        .init(AdminWindowFeature.Screen.self),
        .init(AdminWindowFeature.State.HealthCheck.self),
        .init(AdminWindowFeature.Action.View.HealthCheckAction.self),
        .init(AdminWindowFeature.State.View.self, as: "AppState"),
        .init(AdminWindowFeature.Action.View.self, as: "AppEvent"),
      ],
      aliasing: [
        "healthCheck": "HealthCheck",
        "action": "HealthCheckAction",
        "screen": "Screen",
      ]
    ),
  ]

  func format() throws {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/just")
    proc.currentDirectoryURL = URL(fileURLWithPath: "/Users/jared/gertie/web")
    proc.arguments = ["format-codegen"]
    try proc.run()
  }
}
