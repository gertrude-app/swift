import Core
import Dependencies
import Foundation

extension OnboardingFeature.State {
  struct View: Equatable, Encodable, Sendable {
    var os: MacOSVersion.DocumentationGroup
    var windowOpen: Bool
    var step: Step
    var userRemediationStep: MacUser.RemediationStep?
    var currentUser: MacUser?
    var connectChildRequest: PayloadRequestState<String, String>
    var users: [MacUser]
    var exemptableUserIds: [uid_t]
    var exemptUserIds: [uid_t]

    init(state: AppReducer.State) {
      @Dependency(\.device) var device
      os = device.osVersion().documentationGroup
      windowOpen = state.onboarding.windowOpen
      step = state.onboarding.step
      userRemediationStep = state.onboarding.userRemediationStep
      currentUser = state.onboarding.currentUser
      connectChildRequest = state.onboarding.connectChildRequest
      users = state.onboarding.users
      exemptableUserIds = state.onboarding.exemptableUsers.map(\.id)
      exemptUserIds = state.onboarding.filterUsers?.exempt ?? []
    }
  }
}
