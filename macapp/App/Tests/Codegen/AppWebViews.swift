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
        (AdminWindowFeature.Action.View.HealthCheckAction.self, "HealthCheckAction"),
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
        .init(RequestSuspensionFeature.State.View.self, as: "AppState"),
        .init(RequestSuspensionFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (AdminAccountStatus.self, "AdminAccountStatus"),
      ]
    ),
    AppviewStore(
      at: "Onboarding/onboarding-store.ts",
      namedTypes: [
        .init(OnboardingFeature.State.Step.self, as: "OnboardingStep"),
        .init(MacOSVersion.DocumentationGroup.self, as: "OSGroup"),
        .init(OnboardingFeature.State.MacUser.RemediationStep.self, as: "UserRemediationStep"),
        .init(OnboardingFeature.State.MacUser.self, as: "MacOSUser"),
      ],
      types: [
        .init(OnboardingFeature.State.View.self, as: "AppState"),
        .init(OnboardingFeature.Action.View.self, as: "AppEvent"),
      ],
      localAliases: [
        (OnboardingFeature.State.Step.self, "OnboardingStep"),
        (MacOSVersion.DocumentationGroup.self, "OSGroup"),
        (OnboardingFeature.State.MacUser.RemediationStep.self, "UserRemediationStep"),
        (OnboardingFeature.State.MacUser.self, "MacOSUser"),
        (PayloadRequestState<String, String>.self, "RequestState<string>"),
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
