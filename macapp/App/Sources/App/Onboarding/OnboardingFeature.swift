import ComposableArchitecture
import Foundation

struct OnboardingFeature: Feature {
  struct State: Equatable, Encodable, Sendable {
    struct MacUser: Equatable, Encodable {
      var id: uid_t
      var name: String
      var isAdmin: Bool

      enum RemediationStep: String, Equatable, Encodable {
        case create
        case `switch`
        case demote
        case choose
      }
    }

    var windowOpen = false
    var step: Step = .welcome
    var userRemediationStep: MacUser.RemediationStep?
    var currentUser: MacUser?
    var existingNotificationsSetting: NotificationsSetting?
    var connectChildRequest: PayloadRequestState<String, String> = .idle
    var users: [MacUser] = []
  }

  enum Resume: Codable, Equatable, Sendable {
    case checkingScreenRecordingPermission
    case at(step: State.Step)
  }

  enum Action: Equatable, Sendable {
    enum Webview: Equatable, Sendable {
      case primaryBtnClicked
      case secondaryBtnClicked
      case chooseSwitchToNonAdminUserClicked
      case chooseCreateNonAdminClicked
      case chooseDemoteAdminClicked
      case connectChildSubmitted(Int)
    }

    enum Delegate: Equatable, Sendable {
      case saveCurrentStep(State.Step?)
    }

    case webview(Webview)
    case delegate(Delegate)
    case resume(Resume)
    case receivedDeviceData(
      currentUserId: uid_t,
      users: [MacOSUser],
      notificationsSetting: NotificationsSetting
    )
    case connectUser(TaskResult<UserData>)
    case setStep(State.Step)
    case closeWindow
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.device) var device
    @Dependency(\.filterExtension) var systemExtension
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.monitoring) var monitoring
    @Dependency(\.storage) var storage

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      let step = state.step
      let userIsAdmin = state.currentUser?.isAdmin != false
      switch action {

      case .resume(.at(let step)):
        state.windowOpen = true
        state.step = step
        return .none

      case .resume(.checkingScreenRecordingPermission):
        return .exec { send in
          await send(.setStep(
            await monitoring.screenRecordingPermissionGranted()
              ? .allowScreenshots_success
              : .allowScreenshots_failed
          ))
        }

      case .receivedDeviceData(let currentUserId, let users, let notificationsSetting):
        state.users = users.map(State.MacUser.init)
        state.currentUser = state.users.first(where: { $0.id == currentUserId })
        state.existingNotificationsSetting = notificationsSetting
        return .none

      case .webview(.primaryBtnClicked) where step == .welcome:
        state.step = .confirmGertrudeAccount
        return .exec { send in
          await send(.receivedDeviceData(
            currentUserId: device.currentUserId(),
            users: try await device.listMacOSUsers(),
            notificationsSetting: await device.notificationsSetting()
          ))
        }

      case .webview(.primaryBtnClicked) where step == .confirmGertrudeAccount:
        state.step = .macosUserAccountType
        return .none

      case .webview(.secondaryBtnClicked) where step == .confirmGertrudeAccount:
        state.step = .noGertrudeAccount
        return .none

      case .webview(.secondaryBtnClicked) where step == .noGertrudeAccount:
        return .exec { _ in
          await storage.deleteAll()
          await app.quit()
        }

      case .webview(.primaryBtnClicked) where step == .macosUserAccountType && !userIsAdmin:
        state.step = .getChildConnectionCode
        return .none

      // they choose to ignore the warning about user type and proceed
      case .webview(.secondaryBtnClicked) where step == .macosUserAccountType && userIsAdmin:
        state.step = .getChildConnectionCode
        return .none

      // they click "show me how to fix" on the BAD mac os user landing page
      case .webview(.primaryBtnClicked) where step == .macosUserAccountType && userIsAdmin:
        state.userRemediationStep = state.users.count == 1 ? .create : .choose
        return .send(.delegate(.saveCurrentStep(.macosUserAccountType)))

      case .webview(.chooseDemoteAdminClicked):
        state.userRemediationStep = .demote
        return .none

      case .webview(.chooseCreateNonAdminClicked):
        state.userRemediationStep = .create
        return .none

      case .webview(.chooseSwitchToNonAdminUserClicked):
        state.userRemediationStep = .switch
        return .none

      case .webview(.primaryBtnClicked) where step == .getChildConnectionCode:
        state.step = .connectChild
        return .none

      case .webview(.connectChildSubmitted(let code)):
        state.connectChildRequest = .ongoing
        return .exec { send in
          await send(.connectUser((TaskResult {
            try await api.connectUser(.init(code: code, device: device, app: app))
          })))
        }

      case .connectUser(.success(let user)):
        state.connectChildRequest = .succeeded(payload: user.name)
        return .none

      case .connectUser(.failure(let error)):
        state.connectChildRequest = .failed(error: error.userMessage())
        return .none

      case .webview(.primaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isFailed:
        state.connectChildRequest = .idle
        state.step = .getChildConnectionCode
        return .none

      case .webview(.secondaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isFailed:
        return .exec { _ in
          await device.openWebUrl(.contact)
        }

      case .webview(.primaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isSucceeded:
        state.step = state.existingNotificationsSetting == .alert
          ? .allowScreenshots_required
          : .allowNotifications_start
        return .none

      case .webview(.primaryBtnClicked) where step == .allowNotifications_start:
        state.step = .allowNotifications_grant
        return .exec { _ in
          await device.requestNotificationAuthorization()
          await device.openSystemPrefs(.notifications)
        }

      case .webview(.primaryBtnClicked)
        where step == .allowNotifications_grant || step == .allowNotifications_failed:
        return .exec { send in
          await send(.setStep(
            await device.notificationsSetting() != .none
              ? .allowScreenshots_required
              : .allowNotifications_failed
          ))
        }

      case .webview(.secondaryBtnClicked)
        where step == .allowNotifications_start || step == .allowNotifications_failed:
        state.step = .allowScreenshots_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_required:
        return .exec { send in
          await send(.setStep(
            await monitoring.screenRecordingPermissionGranted()
              ? .allowKeylogging_required
              : .allowScreenshots_openSysSettings
          ))
        }

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_required:
        state.step = .allowKeylogging_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_openSysSettings:
        state.step = .allowScreenshots_grantAndRestart
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_failed:
        state.step = .allowScreenshots_grantAndRestart
        return .exec { _ in
          await device.openSystemPrefs(.security(.screenRecording))
        }

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_failed:
        state.step = .allowKeylogging_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_success:
        state.step = .allowKeylogging_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_required:
        return .exec { send in
          await send(.setStep(
            await monitoring.keystrokeRecordingPermissionGranted()
              ? .installSysExt_explain
              : .allowKeylogging_openSysSettings
          ))
        }

      case .webview(.secondaryBtnClicked) where step == .allowKeylogging_required:
        state.step = .installSysExt_explain
        return .none

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_openSysSettings:
        state.step = .allowKeylogging_grant
        return .none

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_grant:
        return .exec { send in
          await send(.setStep(
            await monitoring.keystrokeRecordingPermissionGranted()
              ? .installSysExt_explain
              : .allowKeylogging_failed
          ))
        }

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_failed:
        state.step = .allowKeylogging_grant
        return .exec { _ in
          await device.openSystemPrefs(.security(.accessibility))
        }

      case .webview(.primaryBtnClicked) where step == .installSysExt_explain:
        return .exec { send in
          switch await systemExtension.state() {
          case .notInstalled:
            await send(.setStep(.installSysExt_allow))
            try? await mainQueue.sleep(for: .seconds(3)) // let them see the explanation gif
            switch await systemExtension.install() {
            case .installedSuccessfully:
              await send(.setStep(.installSysExt_success))
            case .timedOutWaiting, .userClickedDontAllow:
              await send(.setStep(.installSysExt_failed))
            case .alreadyInstalled:
              // should never happen, since checked the condition above
              await send(.setStep(.installSysExt_failed))
            case .activationRequestFailed,
                 .failedToGetBundleIdentifier,
                 .failedToLoadConfig,
                 .failedToSaveConfig:
              await send(.setStep(.installSysExt_failed))
            }
          case .errorLoadingConfig, .unknown:
            await send(.setStep(.installSysExt_failed))
          case .installedAndRunning:
            await send(.setStep(.installSysExt_success))
          case .installedButNotRunning:
            if await systemExtension.start() == .installedAndRunning {
              await send(.setStep(.installSysExt_success))
            } else {
              // TODO: should we try to replace once?
              await send(.setStep(.installSysExt_failed))
            }
          }
        }

      case .webview(.primaryBtnClicked) where step == .installSysExt_allow:
        return .exec { send in
          if await systemExtension.state() == .installedAndRunning {
            await send(.setStep(.installSysExt_success))
          } else {
            await send(.setStep(.installSysExt_failed))
          }
        }

      case .webview(.secondaryBtnClicked) where step == .installSysExt_allow:
        state.step = .installSysExt_failed
        return .none

      case .webview(.primaryBtnClicked) where step == .installSysExt_failed:
        state.step = .installSysExt_explain
        return .none

      case .webview(.secondaryBtnClicked) where step == .installSysExt_failed:
        state.step = .locateMenuBarIcon
        return .none

      case .webview(.primaryBtnClicked) where step == .installSysExt_success:
        state.step = .locateMenuBarIcon
        return .none

      case .webview(.primaryBtnClicked) where step == .locateMenuBarIcon:
        state.step = .viewHealthCheck
        return .none

      case .webview(.primaryBtnClicked) where step == .viewHealthCheck:
        state.step = .howToUseGertrude
        return .none

      case .webview(.primaryBtnClicked) where step == .howToUseGertrude:
        state.step = .finish
        return .none

      case .webview(.primaryBtnClicked) where step == .finish, .closeWindow:
        state.windowOpen = false
        let userConnected = state.connectChildRequest.isSucceeded
        return .exec { _ in
          if userConnected, (await app.isLaunchAtLoginEnabled()) == false {
            await app.enableLaunchAtLogin()
          }
        }

      case .webview(.primaryBtnClicked):
        // TODO: debug assert, and error log
        return .none

      case .webview(.secondaryBtnClicked):
        // TODO: debug assert, and error log
        return .none

      case .setStep(let step):
        state.step = step
        state.windowOpen = true // for resuming
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

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

extension OnboardingFeature.State.MacUser {
  init(_ user: MacOSUser) {
    id = user.id
    name = user.name
    isAdmin = user.type == .admin
  }
}
