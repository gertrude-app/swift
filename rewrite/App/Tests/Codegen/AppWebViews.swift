import Foundation
import Gertie
import TypeScriptInterop

@testable import App
@testable import enum App.FilterState

struct AppWebViews: AggregateCodeGenerator {
  var generators: [CodeGenerator] = [
    AppviewStore(
      at: "lib/shared-types.ts",
      namedTypes: [
        .init(FilterState.self),
        .init(AdminAccountStatus.self),
      ]
    ),
    AppviewStore(
      at: "MenuBar/menubar-store.ts",
      types: [
        .init(MenuBarFeature.State.View.self, as: "AppState"),
        .init(MenuBarFeature.Action.self, as: "AppEvent"),
      ],
      localAliases: [(FilterState.self, "FilterState")]
    ),
    AppviewStore(
      at: "BlockedRequests/blockedrequests-store.ts",
      namedTypes: [
        .init(BlockedRequestsFeature.State.View.Request.self),
      ],
      types: [
        .init(BlockedRequestsFeature.State.View.self, as: "AppState"),
        .init(BlockedRequestsFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (BlockedRequestsFeature.State.View.Request.self, "Request"),
        (AdminAccountStatus.self, "AdminAccountStatus"),
      ]
    ),
    AppviewStore(
      at: "Administrate/administrate-store.ts",
      namedTypes: [
        .init(AdminWindowFeature.Screen.self),
        .init(AdminWindowFeature.State.HealthCheck.self),
        .init(AdminWindowFeature.State.View.ExemptableUser.self),
        .init(AdminWindowFeature.Action.View.HealthCheckAction.self),
        .init(AdminWindowFeature.State.View.Advanced.self, as: "AdvancedState"),
        .init(AdminWindowFeature.Action.View.AdvancedAction.self),
      ],
      types: [
        .init(AdminWindowFeature.State.View.self, as: "AppState"),
        .init(AdminWindowFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (AdminWindowFeature.State.HealthCheck.self, "HealthCheck"),
        (AdminWindowFeature.State.View.Advanced.self, "AdvancedState"),
        // todo, rename in enum now with better ts codegen
        (AdminWindowFeature.Action.View.HealthCheckAction.self, "HealthCheckAction"),
        // todo, rename in enum now with better ts codegen
        (AdminWindowFeature.Action.View.AdvancedAction.self, "AdvancedAction"),
        (AdminWindowFeature.Screen.self, "Screen"),
        (FilterState.self, "FilterState"),
        (
          Failable<[AdminWindowFeature.State.View.ExemptableUser]>.self,
          "Failable<ExemptableUser[]>"
        ),
      ],
      globalAliases: [
        (AdminAccountStatus.self, "AdminAccountStatus"),
        (Failable<AdminAccountStatus>.self, "Failable<AdminAccountStatus>"),
      ]
    ),
    AppviewStore(
      at: "RequestSuspension/requestsuspension-store.ts",
      types: [
        .init(RequestSuspensionFeature.State.self, as: "AppState"),
        .init(RequestSuspensionFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (AdminAccountStatus.self, "AdminAccountStatus"),
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
