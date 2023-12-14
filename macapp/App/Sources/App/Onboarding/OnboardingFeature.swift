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
    var connectChildRequest: PayloadRequestState<String, String> = .idle
    var users: [MacUser] = []
  }

  enum Resume: Codable, Equatable, Sendable {
    case checkingScreenRecordingPermission
    case at(step: State.Step)
  }

  enum Action: Equatable, Sendable {
    enum View: Equatable, Sendable, Decodable {
      case closeWindow
      case primaryBtnClicked
      case secondaryBtnClicked
      case chooseSwitchToNonAdminUserClicked
      case chooseCreateNonAdminClicked
      case chooseDemoteAdminClicked
      case connectChildSubmitted(code: Int)
      case infoModalOpened(step: State.Step, detail: String?)
    }

    enum Delegate: Equatable, Sendable {
      case saveForResume(Resume?)
      case onboardingConfigComplete
    }

    case webview(View)
    case delegate(Delegate)
    case resume(Resume)
    case receivedDeviceData(currentUserId: uid_t, users: [MacOSUser])
    case connectUser(TaskResult<UserData>)
    case setStep(State.Step)
    case sysExtInstallTimedOut
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
        log("resuming at \(step)", "711355aa")
        state.windowOpen = true
        state.step = step
        return .exec { send in
          await send(.receivedDeviceData(
            currentUserId: device.currentUserId(),
            users: try await device.listMacOSUsers()
          ))
        }

      case .resume(.checkingScreenRecordingPermission):
        state.windowOpen = true
        return .exec { send in
          let granted = await monitoring.screenRecordingPermissionGranted()
          log("resume checking screen recording, granted=\(granted)", "5d1d27fe")
          if granted {
            await send(.setStep(.allowScreenshots_success))
          } else {
            await send(.delegate(.saveForResume(.checkingScreenRecordingPermission)))
            await send(.setStep(.allowScreenshots_failed))
          }
        }

      case .receivedDeviceData(let currentUserId, let users):
        state.users = users.map(State.MacUser.init)
        state.currentUser = state.users.first(where: { $0.id == currentUserId })
        return .none

      case .webview(.primaryBtnClicked) where step == .welcome:
        log(step, action, "e712e261")
        state.step = app.inCorrectLocation ? .confirmGertrudeAccount : .wrongInstallDir
        return .exec { send in
          await send(.receivedDeviceData(
            currentUserId: device.currentUserId(),
            users: try await device.listMacOSUsers()
          ))
        }

      case .webview(.primaryBtnClicked) where step == .wrongInstallDir:
        log(step, action, "1d7defca")
        state.windowOpen = false
        return .exec { _ in await app.quit() }

      case .webview(.primaryBtnClicked) where step == .confirmGertrudeAccount:
        log(step, action, "36a1852c")
        state.step = userIsAdmin ? .macosUserAccountType : .getChildConnectionCode
        return .none

      case .webview(.secondaryBtnClicked) where step == .confirmGertrudeAccount:
        log(step, action, "85958bee")
        state.step = .noGertrudeAccount
        return .none

      case .webview(.primaryBtnClicked) where step == .noGertrudeAccount:
        log(step, action, "05820945")
        state.step = userIsAdmin ? .macosUserAccountType : .getChildConnectionCode
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
          await send(.delegate(.saveForResume(.at(step: .macosUserAccountType))))
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
        log("next from connect user success", "34221891")
        return .exec { send in
          await nextRequiredStage(from: .connectChild, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowNotifications_start:
        log(step, action, "b183d96d")
        state.step = .allowNotifications_grant
        return .exec { _ in
          await device.requestNotificationAuthorization()
          await device.openSystemPrefs(.notifications)
        }

      case .webview(.primaryBtnClicked) where step == .allowNotifications_grant:
        log(step, action, "9fa094ac")
        return .exec { send in
          if await device.notificationsSetting() == .none {
            await send(.setStep(.allowNotifications_failed))
          } else {
            await nextRequiredStage(from: step, send)
          }
        }

      case .webview(.secondaryBtnClicked) where step == .allowNotifications_grant:
        log(step, action, "8f9d3c9c")
        state.step = .allowNotifications_failed
        return .none

      case .webview(.primaryBtnClicked) where step == .allowNotifications_failed:
        log(step, action, "b183d96d")
        return .exec { send in
          if await device.notificationsSetting() == .none {
            await device.requestNotificationAuthorization()
            await device.openSystemPrefs(.notifications)
            await send(.setStep(.allowNotifications_grant))
          } else {
            await nextRequiredStage(from: step, send)
          }
        }

      case .webview(.secondaryBtnClicked)
        where step == .allowNotifications_start || step == .allowNotifications_failed:
        log(step, action, "8cf52d46")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_required:
        return .exec { send in
          let granted = await monitoring.screenRecordingPermissionGranted()
          log("primary from .allowScreenshots_required, already granted=\(granted)", "ce78b67b")
          if granted {
            await nextRequiredStage(from: step, send)
          } else {
            try? await monitoring.takeScreenshot(500) // trigger permission prompt
            await send(.delegate(.saveForResume(.checkingScreenRecordingPermission)))
            await send(.setStep(.allowScreenshots_grantAndRestart))
          }
        }

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_required:
        log(step, action, "b2907efa")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_grantAndRestart:
        log(step, action, "c7e2bed4")
        state.step = .allowScreenshots_failed
        return .none

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_grantAndRestart:
        log(step, action, "a85b700c")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_failed:
        log(step, action, "cfb65d32")
        return .exec { send in
          if await monitoring.screenRecordingPermissionGranted() {
            await send(.setStep(.allowScreenshots_success))
          } else {
            await device.openSystemPrefs(.security(.screenRecording))
            await send(.setStep(.allowScreenshots_grantAndRestart))
          }
        }

      case .webview(.secondaryBtnClicked) where step == .allowScreenshots_failed:
        log(step, action, "9616ea42")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowScreenshots_success:
        log(step, action, "fc9a6916")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_required:
        log(step, action, "6db8471f")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.secondaryBtnClicked) where step == .allowKeylogging_required:
        log(step, action, "61a87bb2")
        return .exec { send in
          await nextRequiredStage(from: .installSysExt_explain, send)
        }

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_grant:
        return .exec { send in
          let granted = await monitoring.keystrokeRecordingPermissionGranted()
          log("primary from .allowKeylogging_grant, granted=\(granted)", "ce78b67b")
          if granted {
            await nextRequiredStage(from: step, send)
          } else {
            await send(.setStep(.allowKeylogging_failed))
          }
        }

      case .webview(.secondaryBtnClicked) where step == .allowKeylogging_grant:
        log(step, action, "5ccce8b9")
        return .exec { send in
          if await monitoring.keystrokeRecordingPermissionGranted() {
            await nextRequiredStage(from: step, send)
          } else {
            await send(.setStep(.allowKeylogging_failed))
          }
        }

      case .webview(.primaryBtnClicked) where step == .allowKeylogging_failed:
        log(step, action, "36181833")
        return .exec { send in
          if await monitoring.keystrokeRecordingPermissionGranted() {
            await nextRequiredStage(from: step, send)
          } else {
            await device.openSystemPrefs(.security(.accessibility))
            await send(.setStep(.allowKeylogging_grant))
          }
        }

      case .webview(.secondaryBtnClicked) where step == .allowKeylogging_failed:
        log(step, action, "775f57f9")
        return .exec { send in
          await nextRequiredStage(from: step, send)
        }

      case .webview(.primaryBtnClicked) where step == .installSysExt_explain:
        return .exec { send in
          let startingState = await systemExtension.state()
          log("primary from .installSysExt_explain, state=\(startingState)", "e585331d")
          switch startingState {
          case .notInstalled:
            await send(.setStep(.installSysExt_allow))
            try? await mainQueue.sleep(for: .seconds(3)) // let them see the explanation gif
            let installResult = await systemExtension.installOverridingTimeout(60 * 4) // 4 minutes
            log("sys ext install result=\(installResult)", "adbc0453")
            switch installResult {
            case .installedSuccessfully:
              await send(.setStep(.installSysExt_success))
            case .timedOutWaiting:
              await send(.sysExtInstallTimedOut)
            case .userClickedDontAllow:
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

      case .sysExtInstallTimedOut where step < .installSysExt_success && state.windowOpen:
        log("sys ext install timed out, moving to fail", "83da9790")
        state.step = .installSysExt_failed
        return .none

      case .sysExtInstallTimedOut:
        log("ignoring sys ext install timeout, past install stage", "2c03ab74")
        return .none

      case .webview(.primaryBtnClicked) where step == .installSysExt_allow,
           .webview(.secondaryBtnClicked) where step == .installSysExt_allow:
        return .exec { send in
          let state = await systemExtension.state()
          log("\(action) from .installSysExt_allow, state=\(state)", "b0e6e683")
          if state == .installedAndRunning {
            await send(.setStep(.installSysExt_success))
          } else {
            await send(.setStep(.installSysExt_failed))
          }
        }

      case .webview(.primaryBtnClicked) where step == .installSysExt_failed:
        log(step, action, "2e246f1d")
        state.step = .installSysExt_explain
        return .none

      case .webview(.primaryBtnClicked) where step == .installSysExt_success,
           .webview(.secondaryBtnClicked) where step == .installSysExt_failed:
        log(step, action, "78bded66")
        state.step = .locateMenuBarIcon
        return .exec { send in
          await send(.delegate(.onboardingConfigComplete))
        }

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

      case .webview(.primaryBtnClicked) where step == .finish,
           .closeWindow,
           .webview(.closeWindow):
        let childConnected = state.connectChildRequest.isSucceeded
        log("bba204bc", "close from \(step), childConnected=\(childConnected)")
        state.windowOpen = false
        guard childConnected else {
          return .exec { _ in
            let persisted = try await storage.loadPersistentState()
            if persisted?.user == nil, step < .allowNotifications_start {
              // unexpected super early bail, so we need to delete all storage and quit
              // so that if they launch Gertrude again, they get the onboarding flow again
              await storage.deleteAll()
              await app.quit()
            }
          }
        }
        return .exec { send in
          if await app.isLaunchAtLoginEnabled() == false {
            await app.enableLaunchAtLogin()
          }
          if step < .locateMenuBarIcon {
            // unexpected early bail, so we need to start protection
            await send(.delegate(.onboardingConfigComplete))
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
        return .none

      case .webview(.infoModalOpened(let step, let detail)):
        log("info modal opened at .\(step), detail=\(detail ?? "(nil)")", "f77ef50c")
        return .none

      case .delegate:
        return .none
      }
    }

    func nextRequiredStage(from current: State.Step, _ send: Send<Action>) async {
      if current < .allowNotifications_start {
        if await device.notificationsSetting() != .alert {
          log("notifications not .alert yet", "ec99a6ea")
          return await send(.setStep(.allowNotifications_start))
        }
        log("notifications already .alert, skipping stage", "f2988b3c")
      }

      if current < .allowScreenshots_required {
        if await monitoring.screenRecordingPermissionGranted() == false {
          log("screen recording not granted yet", "3edcf34f")
          return await send(.setStep(.allowScreenshots_required))
        }
        log("screenshots already allowed, skipping stage", "6e2e204c")
      }

      // if we're past the screenshot stage, we know we don't want to resume again
      // so, defensively always remove the onboarding resume state at this point
      await send(.delegate(.saveForResume(nil)))

      // checking keylogging pops up the system prompt, so we always
      // have to land them on this screen once, and test later.
      // if they click "next" from .allowKeylogging_required, and the perms
      // have already been granted, they'll move straight on, and not see a prompt
      if current < .allowKeylogging_required {
        log("can't test keylogging yet, go to required", "fd0bfa95")
        return await send(.setStep(.allowKeylogging_required))
      }

      if current == .allowKeylogging_required {
        if await monitoring.keystrokeRecordingPermissionGranted() == false {
          log("keylogging not granted yet", "5d5275e5")
          return await send(.setStep(.allowKeylogging_grant))
        }
        log("keylogging already allowed, skipping stage", "51ed2be8")
      }

      if await systemExtension.state() != .installedAndRunning {
        log("sys ext not installed and running yet", "b493ebde")
        return await send(.setStep(.installSysExt_explain))
      }

      log("sys ext already installed and running, skipping stage", "b0e6e683")

      await send(.delegate(.onboardingConfigComplete))
      await send(.setStep(.locateMenuBarIcon))
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
  func eventMeta() -> String {
    "os: \(device.osVersion().name), sn: \(device.serialNumber() ?? ""), time: \(Date())"
  }

  func log(_ msg: String, _ id: String) {
    #if !DEBUG
      Task { interestingEvent(id: id, "[onboarding]: \(msg), \(eventMeta())") }
    #else
      if ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"] == nil {
        print("\n[onboarding]: `\(id)` \(msg), \(eventMeta())\n")
      }
    #endif
  }

  func log(_ step: State.Step, _ action: Action, _ id: String) {
    let shortAction = "\(action)"
      .replacingOccurrences(of: "App.OnboardingFeature.Action.View", with: "")
    log("received .\(shortAction) from step .\(step)", id)
  }
}
