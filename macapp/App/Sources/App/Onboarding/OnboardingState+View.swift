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
      self.os = device.osVersion().documentationGroup
      self.windowOpen = state.onboarding.windowOpen
      self.step = state.onboarding.step
      self.userRemediationStep = state.onboarding.userRemediationStep
      self.currentUser = state.onboarding.currentUser
      self.connectChildRequest = state.onboarding.connectChildRequest
      self.users = state.onboarding.users
      self.exemptableUserIds = state.onboarding.exemptableUsers.map(\.id)
      self.exemptUserIds = state.onboarding.filterUsers?.exempt ?? []
    }
  }
}
