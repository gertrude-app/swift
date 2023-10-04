
extension OnboardingFeature.State {
  enum Step: Equatable, Codable {
    case welcome
    case confirmGertrudeAccount
    case noGertrudeAccount
    case macosUserAccountType
    case getChildConnectionCode
    case connectChild
    case allowNotifications_start
    case allowNotifications_grant
    case allowNotifications_failed
    case allowScreenshots_required
    case allowScreenshots_openSysSettings
    case allowScreenshots_grantAndRestart

    // these two states exist to give us a landing spot for resuming
    // onboarding after the grant -> quit & reopen flow
    case allowScreenshots_failed
    case allowScreenshots_success

    case allowKeylogging_required
    case allowKeylogging_openSysSettings
    case allowKeylogging_grant
    case allowKeylogging_failed

    case installSysExt_explain
    case installSysExt_allow
    case installSysExt_failed
    case installSysExt_success

    case locateMenuBarIcon
    case viewHealthCheck
    case howToUseGertrude
    case finish
  }
}

extension OnboardingFeature.State.Step {
  var primaryFallbackNextStep: Self {
    switch self {
    case .welcome:
      return .confirmGertrudeAccount
    case .confirmGertrudeAccount:
      return .macosUserAccountType
    case .noGertrudeAccount:
      return .macosUserAccountType
    case .macosUserAccountType:
      return .getChildConnectionCode
    case .getChildConnectionCode:
      return .connectChild
    case .connectChild:
      return .allowNotifications_start
    case .allowNotifications_start:
      return .allowNotifications_grant
    case .allowNotifications_grant:
      return .allowScreenshots_required
    case .allowNotifications_failed:
      return .allowScreenshots_required
    case .allowScreenshots_required:
      return .allowScreenshots_openSysSettings
    case .allowScreenshots_openSysSettings:
      return .allowScreenshots_grantAndRestart
    case .allowScreenshots_grantAndRestart:
      return .allowScreenshots_success
    case .allowScreenshots_failed:
      return .allowKeylogging_required
    case .allowScreenshots_success:
      return .allowKeylogging_required
    case .allowKeylogging_required:
      return .allowKeylogging_openSysSettings
    case .allowKeylogging_openSysSettings:
      return .allowKeylogging_grant
    case .allowKeylogging_grant:
      return .installSysExt_explain
    case .allowKeylogging_failed:
      return .installSysExt_explain
    case .installSysExt_explain:
      return .installSysExt_allow
    case .installSysExt_allow:
      return .installSysExt_success
    case .installSysExt_failed:
      return .installSysExt_success
    case .installSysExt_success:
      return .locateMenuBarIcon
    case .locateMenuBarIcon:
      return .viewHealthCheck
    case .viewHealthCheck:
      return .howToUseGertrude
    case .howToUseGertrude:
      return .finish
    case .finish:
      return .finish
    }
  }

  var secondaryFallbackNextStep: Self {
    switch self {
    case .welcome:
      return .welcome
    case .confirmGertrudeAccount:
      return .welcome
    case .noGertrudeAccount:
      return .confirmGertrudeAccount
    case .macosUserAccountType:
      return .confirmGertrudeAccount
    case .getChildConnectionCode:
      return .macosUserAccountType
    case .connectChild:
      return .getChildConnectionCode
    case .allowNotifications_start:
      return .connectChild
    case .allowNotifications_grant:
      return .allowNotifications_start
    case .allowNotifications_failed:
      return .allowNotifications_grant
    case .allowScreenshots_required:
      return .allowNotifications_start
    case .allowScreenshots_openSysSettings:
      return .allowScreenshots_required
    case .allowScreenshots_grantAndRestart:
      return .allowScreenshots_openSysSettings
    case .allowScreenshots_failed:
      return .allowScreenshots_required
    case .allowScreenshots_success:
      return .allowScreenshots_grantAndRestart
    case .allowKeylogging_required:
      return .allowScreenshots_required
    case .allowKeylogging_openSysSettings:
      return .allowKeylogging_required
    case .allowKeylogging_grant:
      return .allowKeylogging_openSysSettings
    case .allowKeylogging_failed:
      return .allowKeylogging_required
    case .installSysExt_explain:
      return .allowKeylogging_required
    case .installSysExt_allow:
      return .installSysExt_explain
    case .installSysExt_failed:
      return .installSysExt_explain
    case .installSysExt_success:
      return .installSysExt_explain
    case .locateMenuBarIcon:
      return .installSysExt_explain
    case .viewHealthCheck:
      return .locateMenuBarIcon
    case .howToUseGertrude:
      return .viewHealthCheck
    case .finish:
      return .howToUseGertrude
    }
  }
}
