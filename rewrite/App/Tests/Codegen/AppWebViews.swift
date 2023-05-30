import Foundation
import Gertie

@testable import App
@testable import enum App.FilterState

struct AppWebViews: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    AppviewStore(
      at: "lib/shared-types.ts",
      generating: [
        .init(FilterState.self),
        .init(AdminAccountStatus.self),
      ]
    ),
    AppviewStore(
      at: "MenuBar/menubar-store.ts",
      generating: [
        .init(MenuBarFeature.State.View.self, as: "AppState"),
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
      aliasing: [
        "requests": "Request[]",
        "adminAccountStatus": "AdminAccountStatus",
      ]
    ),
    AppviewStore(
      at: "Administrate/administrate-store.ts",
      generating: [
        .init(AdminWindowFeature.Screen.self),
        .init(AdminWindowFeature.State.HealthCheck.self),
        .init(AdminWindowFeature.State.View.ExemptableUser.self),
        .init(AdminWindowFeature.Action.View.HealthCheckAction.self),
        .init(AdminWindowFeature.State.View.Advanced.self, as: "AdvancedState"),
        .init(AdminWindowFeature.Action.View.AdvancedAction.self),
        .init(AdminWindowFeature.State.View.self, as: "AppState"),
        .init(AdminWindowFeature.Action.View.self, as: "AppEvent"),
      ],
      aliasing: [
        "healthCheck": "HealthCheck",
        "advanced": "AdvancedState",
        "healthCheckAction": "HealthCheckAction",
        "advancedAction": "AdvancedAction",
        "screen": "Screen",
        "filterState": "FilterState",
        "accountStatus": "Failable<AdminAccountStatus>",
        "exemptableUsers": "Failable<ExemptableUser[]>",
      ]
    ),
    AppviewStore(
      at: "RequestSuspension/requestsuspension-store.ts",
      generating: [
        .init(RequestSuspensionFeature.State.self, as: "AppState"),
        .init(RequestSuspensionFeature.Action.View.self, as: "AppEvent"),
      ],
      aliasing: [
        "adminAccountStatus": "AdminAccountStatus",
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
