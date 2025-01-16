
extension OnboardingFeature.State {
  enum Step: String, Equatable, Codable {
    case welcome

    // wrong install dir
    case wrongInstallDir

    // account
    case confirmGertrudeAccount
    case noGertrudeAccount

    // os user type
    case macosUserAccountType

    // connection
    case getChildConnectionCode
    case connectChild

    // how to use gifs
    case howToUseGifs

    // notifications
    case allowNotifications_start
    case allowNotifications_grant
    case allowNotifications_failed

    // full disk access
    case allowFullDiskAccess_grantAndRestart
    // next two give landing spots for resuming after quit/reopen
    case allowFullDiskAccess_failed
    case allowFullDiskAccess_success

    // screenshots
    case allowScreenshots_required
    case allowScreenshots_grantAndRestart
    // next two give landing spots for resuming after quit/reopen
    case allowScreenshots_failed
    case allowScreenshots_success

    // keylogging
    case allowKeylogging_required
    case allowKeylogging_grant
    case allowKeylogging_failed

    // sys ext
    case installSysExt_explain
    case installSysExt_trick
    case installSysExt_allow
    case installSysExt_failed
    case installSysExt_success

    // wrap up
    case exemptUsers
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
    case .wrongInstallDir:
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
      return .howToUseGifs
    case .howToUseGifs:
      return .allowNotifications_start
    case .allowNotifications_start:
      return .allowNotifications_grant
    case .allowNotifications_grant:
      return .allowScreenshots_required
    case .allowNotifications_failed:
      return .allowFullDiskAccess_grantAndRestart
    case .allowFullDiskAccess_grantAndRestart:
      return .allowFullDiskAccess_success
    case .allowFullDiskAccess_success:
      return .allowScreenshots_required
    case .allowFullDiskAccess_failed:
      return .allowScreenshots_required
    case .allowScreenshots_required:
      return .allowScreenshots_grantAndRestart
    case .allowScreenshots_grantAndRestart:
      return .allowScreenshots_success
    case .allowScreenshots_failed:
      return .allowKeylogging_required
    case .allowScreenshots_success:
      return .allowKeylogging_required
    case .allowKeylogging_required:
      return .allowKeylogging_grant
    case .allowKeylogging_grant:
      return .installSysExt_explain
    case .allowKeylogging_failed:
      return .installSysExt_explain
    case .installSysExt_explain:
      return .installSysExt_trick
    case .installSysExt_trick:
      return .installSysExt_allow
    case .installSysExt_allow:
      return .installSysExt_success
    case .installSysExt_failed:
      return .installSysExt_success
    case .installSysExt_success:
      return .locateMenuBarIcon
    case .exemptUsers:
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
    case .wrongInstallDir:
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
    case .howToUseGifs:
      return .connectChild

    case .allowNotifications_start:
      return .howToUseGifs
    case .allowNotifications_grant:
      return .allowNotifications_start
    case .allowNotifications_failed:
      return .allowNotifications_grant

    case .allowFullDiskAccess_grantAndRestart:
      return .allowNotifications_start
    case .allowFullDiskAccess_failed:
      return .allowFullDiskAccess_grantAndRestart
    case .allowFullDiskAccess_success:
      return .allowFullDiskAccess_grantAndRestart

    case .allowScreenshots_required:
      return .allowFullDiskAccess_grantAndRestart

    case .allowScreenshots_grantAndRestart:
      return .allowScreenshots_required
    case .allowScreenshots_failed:
      return .allowScreenshots_required
    case .allowScreenshots_success:
      return .allowScreenshots_grantAndRestart
    case .allowKeylogging_required:
      return .allowScreenshots_required
    case .allowKeylogging_grant:
      return .allowKeylogging_required
    case .allowKeylogging_failed:
      return .allowKeylogging_required
    case .installSysExt_explain:
      return .allowKeylogging_required
    case .installSysExt_trick:
      return .installSysExt_explain
    case .installSysExt_allow:
      return .installSysExt_trick
    case .installSysExt_failed:
      return .installSysExt_explain
    case .installSysExt_success:
      return .installSysExt_explain
    case .exemptUsers:
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

extension OnboardingFeature.State.Step: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.asInt < rhs.asInt
  }

  private var asInt: Int {
    switch self {
    case .welcome: return 0
    case .wrongInstallDir: return 3
    case .confirmGertrudeAccount: return 5
    case .noGertrudeAccount: return 10
    case .macosUserAccountType: return 15
    case .getChildConnectionCode: return 20
    case .connectChild: return 25
    case .howToUseGifs: return 28
    case .allowNotifications_start: return 30
    case .allowNotifications_grant: return 35
    case .allowNotifications_failed: return 40
    case .allowFullDiskAccess_grantAndRestart: return 42
    case .allowFullDiskAccess_failed: return 43
    case .allowFullDiskAccess_success: return 44
    case .allowScreenshots_required: return 45
    case .allowScreenshots_grantAndRestart: return 55
    case .allowScreenshots_failed: return 60
    case .allowScreenshots_success: return 65
    case .allowKeylogging_required: return 70
    case .allowKeylogging_grant: return 80
    case .allowKeylogging_failed: return 85
    case .installSysExt_explain: return 90
    case .installSysExt_trick: return 92
    case .installSysExt_allow: return 95
    case .installSysExt_failed: return 100
    case .installSysExt_success: return 105
    case .exemptUsers: return 108
    case .locateMenuBarIcon: return 110
    case .viewHealthCheck: return 115
    case .howToUseGertrude: return 120
    case .finish: return 125
    }
  }
}
