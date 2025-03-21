
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
    case encourageFilterSuspensions
    case howToUseGertrude
    case finish
  }
}

extension OnboardingFeature.State.Step {
  var primaryFallbackNextStep: Self {
    switch self {
    case .welcome:
      .confirmGertrudeAccount
    case .wrongInstallDir:
      .confirmGertrudeAccount
    case .confirmGertrudeAccount:
      .macosUserAccountType
    case .noGertrudeAccount:
      .macosUserAccountType
    case .macosUserAccountType:
      .getChildConnectionCode
    case .getChildConnectionCode:
      .connectChild
    case .connectChild:
      .howToUseGifs
    case .howToUseGifs:
      .allowNotifications_start
    case .allowNotifications_start:
      .allowNotifications_grant
    case .allowNotifications_grant:
      .allowScreenshots_required
    case .allowNotifications_failed:
      .allowFullDiskAccess_grantAndRestart
    case .allowFullDiskAccess_grantAndRestart:
      .allowFullDiskAccess_success
    case .allowFullDiskAccess_success:
      .allowScreenshots_required
    case .allowFullDiskAccess_failed:
      .allowScreenshots_required
    case .allowScreenshots_required:
      .allowScreenshots_grantAndRestart
    case .allowScreenshots_grantAndRestart:
      .allowScreenshots_success
    case .allowScreenshots_failed:
      .allowKeylogging_required
    case .allowScreenshots_success:
      .allowKeylogging_required
    case .allowKeylogging_required:
      .allowKeylogging_grant
    case .allowKeylogging_grant:
      .installSysExt_explain
    case .allowKeylogging_failed:
      .installSysExt_explain
    case .installSysExt_explain:
      .installSysExt_trick
    case .installSysExt_trick:
      .installSysExt_allow
    case .installSysExt_allow:
      .installSysExt_success
    case .installSysExt_failed:
      .installSysExt_success
    case .installSysExt_success:
      .locateMenuBarIcon
    case .exemptUsers:
      .locateMenuBarIcon
    case .locateMenuBarIcon:
      .viewHealthCheck
    case .viewHealthCheck:
      .encourageFilterSuspensions
    case .encourageFilterSuspensions:
      .howToUseGertrude
    case .howToUseGertrude:
      .finish
    case .finish:
      .finish
    }
  }

  var secondaryFallbackNextStep: Self {
    switch self {
    case .welcome:
      .welcome
    case .wrongInstallDir:
      .welcome
    case .confirmGertrudeAccount:
      .welcome
    case .noGertrudeAccount:
      .confirmGertrudeAccount
    case .macosUserAccountType:
      .confirmGertrudeAccount
    case .getChildConnectionCode:
      .macosUserAccountType
    case .connectChild:
      .getChildConnectionCode
    case .howToUseGifs:
      .connectChild
    case .allowNotifications_start:
      .howToUseGifs
    case .allowNotifications_grant:
      .allowNotifications_start
    case .allowNotifications_failed:
      .allowNotifications_grant
    case .allowFullDiskAccess_grantAndRestart:
      .allowNotifications_start
    case .allowFullDiskAccess_failed:
      .allowFullDiskAccess_grantAndRestart
    case .allowFullDiskAccess_success:
      .allowFullDiskAccess_grantAndRestart
    case .allowScreenshots_required:
      .allowFullDiskAccess_grantAndRestart
    case .allowScreenshots_grantAndRestart:
      .allowScreenshots_required
    case .allowScreenshots_failed:
      .allowScreenshots_required
    case .allowScreenshots_success:
      .allowScreenshots_grantAndRestart
    case .allowKeylogging_required:
      .allowScreenshots_required
    case .allowKeylogging_grant:
      .allowKeylogging_required
    case .allowKeylogging_failed:
      .allowKeylogging_required
    case .installSysExt_explain:
      .allowKeylogging_required
    case .installSysExt_trick:
      .installSysExt_explain
    case .installSysExt_allow:
      .installSysExt_trick
    case .installSysExt_failed:
      .installSysExt_explain
    case .installSysExt_success:
      .installSysExt_explain
    case .exemptUsers:
      .installSysExt_explain
    case .locateMenuBarIcon:
      .installSysExt_explain
    case .viewHealthCheck:
      .locateMenuBarIcon
    case .encourageFilterSuspensions:
      .viewHealthCheck
    case .howToUseGertrude:
      .encourageFilterSuspensions
    case .finish:
      .howToUseGertrude
    }
  }
}

extension OnboardingFeature.State.Step: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.asInt < rhs.asInt
  }

  private var asInt: Int {
    switch self {
    case .welcome: 0
    case .wrongInstallDir: 3
    case .confirmGertrudeAccount: 5
    case .noGertrudeAccount: 10
    case .macosUserAccountType: 15
    case .getChildConnectionCode: 20
    case .connectChild: 25
    case .howToUseGifs: 28
    case .allowNotifications_start: 30
    case .allowNotifications_grant: 35
    case .allowNotifications_failed: 40
    case .allowFullDiskAccess_grantAndRestart: 42
    case .allowFullDiskAccess_failed: 43
    case .allowFullDiskAccess_success: 44
    case .allowScreenshots_required: 45
    case .allowScreenshots_grantAndRestart: 55
    case .allowScreenshots_failed: 60
    case .allowScreenshots_success: 65
    case .allowKeylogging_required: 70
    case .allowKeylogging_grant: 80
    case .allowKeylogging_failed: 85
    case .installSysExt_explain: 90
    case .installSysExt_trick: 92
    case .installSysExt_allow: 95
    case .installSysExt_failed: 100
    case .installSysExt_success: 105
    case .exemptUsers: 108
    case .locateMenuBarIcon: 110
    case .viewHealthCheck: 115
    case .encourageFilterSuspensions: 117
    case .howToUseGertrude: 120
    case .finish: 125
    }
  }
}
