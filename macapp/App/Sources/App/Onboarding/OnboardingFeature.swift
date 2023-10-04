import ClientInterfaces
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
        log("resuming at \(step)", "711355aa")
        return .none

      case .resume(.checkingScreenRecordingPermission):
        return .exec { send in
          let granted = await monitoring.screenRecordingPermissionGranted()
          log("resume checking screen recording, granted=\(granted)", "5d1d27fe")
          await send(.setStep(
            granted
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
        log(step, action, "e712e261")
        state.step = .confirmGertrudeAccount
        return .exec { send in
          await send(.receivedDeviceData(
            currentUserId: device.currentUserId(),
            users: try await device.listMacOSUsers(),
            notificationsSetting: await device.notificationsSetting()
          ))
        }

      case .webview(.primaryBtnClicked) where step == .confirmGertrudeAccount:
        log(step, action, "36a1852c")
        state.step = .macosUserAccountType
        return .none

      case .webview(.secondaryBtnClicked) where step == .confirmGertrudeAccount:
        log(step, action, "85958bee")
        state.step = .noGertrudeAccount
        return .none

      case .webview(.secondaryBtnClicked) where step == .noGertrudeAccount:
        log("quit from no gertrude acct", "236defcb")
        return .exec { _ in
          await storage.deleteAll()
          await app.quit()
        }

      case .webview(.primaryBtnClicked) where step == .macosUserAccountType && !userIsAdmin:
        log("macos account type correct next clicked", "0a29be72")
        state.step = .getChildConnectionCode
        return .none

      // they choose to ignore the warning about user type and proceed
      case .webview(.secondaryBtnClicked) where step == .macosUserAccountType && userIsAdmin:
        log("skip admin user account warning", "d044eb17")
        state.step = .getChildConnectionCode
        return .none

      // they click "show me how to fix" on the BAD mac os user landing page
      case .webview(.primaryBtnClicked) where step == .macosUserAccountType && userIsAdmin:
        state.userRemediationStep = state.users.count == 1 ? .create : .choose
        log("show me how to fix admin user clicked, \(state.users.count) users", "74179c5c")
        return .exec { send in
          await send(.delegate(.saveCurrentStep(.macosUserAccountType)))
        }

      case .webview(.chooseDemoteAdminClicked):
        log(step, action, "d638fa96")
        state.userRemediationStep = .demote
        return .none

      case .webview(.chooseCreateNonAdminClicked):
        log(step, action, "c63bf016")
        state.userRemediationStep = .create
        return .none

      case .webview(.chooseSwitchToNonAdminUserClicked):
        log(step, action, "68fdb44a")
        state.userRemediationStep = .switch
        return .none

      case .webview(.primaryBtnClicked) where step == .getChildConnectionCode:
        log(step, action, "550d9504")
        state.step = .connectChild
        return .none

      case .webview(.connectChildSubmitted(let code)):
        log(step, action, "3d6b89a8")
        state.connectChildRequest = .ongoing
        return .exec { send in
          await send(.connectUser((TaskResult {
            try await api.connectUser(.init(code: code, device: device, app: app))
          })))
        }

      case .connectUser(.success(let user)):
        log("connect user success", "3a1ac301")
        state.connectChildRequest = .succeeded(payload: user.name)
        return .none

      case .connectUser(.failure(let error)):
        log("connect user failed \(error)", "0ed97f9a")
        state.connectChildRequest = .failed(error: error.userMessage())
        return .none

      case .webview(.primaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isFailed:
        log("retry connect user", "c69844b8")
        state.connectChildRequest = .idle
        state.step = .getChildConnectionCode
        return .none

      case .webview(.secondaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isFailed:
        log("connect user failed secondary", "08de43c1")
        return .exec { _ in
          await device.openWebUrl(.contact)
        }

      case .webview(.primaryBtnClicked)
        where step == .connectChild && state.connectChildRequest.isSucceeded:
        log("next from connect child success", "34221891")
        state.step = state.existingNotificationsSetting == .alert
          ? .allowScreenshots_required
          : .allowNotifications_start
        return .none

      case .webview(.primaryBtnClicked) where step == .allowNotifications_start:
        log(step, action, "b183d96d")
        state.step = .allowNotifications_grant
        return .exec { _ in
          await device.requestNotificationAuthorization()
          await device.openSystemPrefs(.notifications)
        }

      case .webview(.primaryBtnClicked)
        where step == .allowNotifications_grant || step == .allowNotifications_failed:
        log(step, action, "9fa094ac")
        return .exec { send in
          await send(.setStep(
            await device.notificationsSetting() != .none
              ? .allowScreenshots_required
              : .allowNotifications_failed
          ))
        }

      case .webview(.secondaryBtnClicked)
        where step == .allowNotifications_start || step == .allowNotifications_failed:
        log(step, action, "8cf52d46")
        state.step = .allowScreenshots_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_required:
        return .exec { send in
          let granted = await monitoring.screenRecordingPermissionGranted()
          log("primary from .allowScreenshots_required, already granted=\(granted)", "ce78b67b")
          await send(.setStep(
            granted
              ? .allowKeylogging_required
              : .allowScreenshots_openSysSettings
          ))
        }

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_required:
        log(step, action, "b2907efa")
        state.step = .allowKeylogging_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_openSysSettings:
        log(step, action, "4e52e7d8")
        state.step = .allowScreenshots_grantAndRestart
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_failed:
        log(step, action, "cfb65d32")
        state.step = .allowScreenshots_grantAndRestart
        return .exec { _ in
          await device.openSystemPrefs(.security(.screenRecording))
        }

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_failed:
        log(step, action, "9616ea42")
        state.step = .allowKeylogging_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_success:
        log(step, action, "fc9a6916")
        state.step = .allowKeylogging_required
        return .none

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_required:
        return .exec { send in
          let granted = await monitoring.keystrokeRecordingPermissionGranted()
          log("primary from .allowKeylogging_required, already granted=\(granted)", "ce78b67b")
          await send(.setStep(
            granted
              ? .installSysExt_explain
              : .allowKeylogging_openSysSettings
          ))
        }

      case .webview(.secondaryBtnClicked) where step == .allowKeylogging_required:
        log(step, action, "61a87bb2")
        state.step = .installSysExt_explain
        return .none

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_openSysSettings:
        log(step, action, "c2e08e19")
        state.step = .allowKeylogging_grant
        return .none

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_grant:
        return .exec { send in
          let granted = await monitoring.keystrokeRecordingPermissionGranted()
          log("primary from .allowKeylogging_grant, granted=\(granted)", "ce78b67b")
          await send(.setStep(
            granted
              ? .installSysExt_explain
              : .allowKeylogging_failed
          ))
        }

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_failed:
        state.step = .allowKeylogging_grant
        log(step, action, "36181833")
        return .exec { _ in
          await device.openSystemPrefs(.security(.accessibility))
        }

      case .webview(.primaryBtnClicked) where step == .installSysExt_explain:
        return .exec { send in
          let startingState = await systemExtension.state()
          log("primary from .installSysExt_explain, state=\(startingState)", "e585331d")
          switch startingState {
          case .notInstalled:
            await send(.setStep(.installSysExt_allow))
            try? await mainQueue.sleep(for: .seconds(3)) // let them see the explanation gif
            let installResult = await systemExtension.install()
            log("sys ext install result=\(installResult)", "adbc0453")
            switch installResult {
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
              log("non-running sys ext started successfully", "d0021f5d")
              await send(.setStep(.installSysExt_success))
            } else {
              // TODO: should we try to replace once?
              await send(.setStep(.installSysExt_failed))
            }
          }
        }

      case .webview(.primaryBtnClicked) where step == .installSysExt_allow:
        return .exec { send in
          let state = await systemExtension.state()
          log("primary from .installSysExt_allow, state=\(state)", "b0e6e683")
          if state == .installedAndRunning {
            await send(.setStep(.installSysExt_success))
          } else {
            await send(.setStep(.installSysExt_failed))
          }
        }

      case .webview(.secondaryBtnClicked) where step == .installSysExt_allow:
        log(step, action, "7859b4e8")
        state.step = .installSysExt_failed
        return .none

      case .webview(.primaryBtnClicked) where step == .installSysExt_failed:
        log(step, action, "2e246f1d")
        state.step = .installSysExt_explain
        return .none

      case .webview(.secondaryBtnClicked) where step == .installSysExt_failed:
        log(step, action, "78bded66")
        state.step = .locateMenuBarIcon
        return .none

      case .webview(.primaryBtnClicked) where step == .installSysExt_success:
        log(step, action, "7009a9cf")
        state.step = .locateMenuBarIcon
        return .none

      case .webview(.primaryBtnClicked) where step == .locateMenuBarIcon:
        log(step, action, "d0a159fd")
        state.step = .viewHealthCheck
        return .none

      case .webview(.primaryBtnClicked) where step == .viewHealthCheck:
        log(step, action, "5c73a171")
        state.step = .howToUseGertrude
        return .none

      case .webview(.primaryBtnClicked) where step == .howToUseGertrude:
        log(step, action, "eb044990")
        state.step = .finish
        return .none

      case .webview(.primaryBtnClicked) where step == .finish, .closeWindow:
        state.windowOpen = false
        let userConnected = state.connectChildRequest.isSucceeded
        log("\(action), step=\(step), userConnected=\(userConnected)", "936082d4")
        return .exec { _ in
          if userConnected, (await app.isLaunchAtLoginEnabled()) == false {
            await app.enableLaunchAtLogin()
          }
        }

      case .webview(.primaryBtnClicked):
        assertionFailure("Unhandled primary button click")
        unexpectedError(id: "56bce346", detail: "step: \(step)")
        state.step = step.primaryFallbackNextStep
        return .none

      case .webview(.secondaryBtnClicked):
        assertionFailure("Unhandled secondary button click")
        unexpectedError(id: "22bfde1a", detail: "step: \(step)")
        state.step = step.secondaryFallbackNextStep
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

extension OnboardingFeature.State.MacUser {
  init(_ user: MacOSUser) {
    id = user.id
    name = user.name
    isAdmin = user.type == .admin
  }
}

extension OnboardingFeature.Reducer {
  func log(_ msg: String, _ id: String) {
    #if !DEBUG
      Task {
        let eventMeta = "os: \(device.osVersion().name), sn: \(device.serialNumber() ?? "")"
        interestingEvent(id: id, "[onboarding]: \(msg), \(eventMeta)")
      }
    #endif
  }

  func log(_ step: State.Step, _ action: Action, _ id: String) {
    log("received action \(action) from step \(step)", id)
  }
}
