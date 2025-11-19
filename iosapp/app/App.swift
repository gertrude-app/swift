import ComposableArchitecture
import LibApp
import SwiftUI

struct AppView: View {
  @Bindable var store: StoreOf<IOSReducer>

  @Environment(\.colorScheme) var cs
  @Environment(\.openURL) var openLink

  var body: some View {
    Group {
      if let clearCacheStore = self.store.scope(
        state: \.onboarding.clearCache,
        action: \.interactive.onboardingClearCache,
      ) {
        ClearingCacheView(
          store: clearCacheStore,
          clearedMessage: "Done! Previously downloaded GIFs should be gone!",
          clearedBtnLabel: "Next",
        )
        .onAppear { clearCacheStore.send(.onAppear) }
      } else {
        switch self.store.screen {
        case .launching: EmptyView()

        case .onboarding(.happyPath(.hiThere)):
          WelcomeView {
            self.store.send(.interactive(.onboardingBtnTapped(.primary, "Get Started")))
          }
          .onShake {
            #if DEBUG
              self.store.send(.interactive(.receivedShake))
            #endif
          }

        case .onboarding(.happyPath(.timeExpectation)):
          ButtonScreenView(
            text: "The setup usually takes about 5-7 minutes, but in some cases extra steps are required.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.confirmChildsDevice)):
          ButtonScreenView(
            text: "Is this the device you want to protect?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.explainMinorOrSupervised)):
          ButtonScreenView(
            text: "Apple only allows Gertrude to do it’s job on two kinds of devices:",
            primary: self.btn(text: "Next", .primary),
            listItems: ["Devices used by children under 18", "Supervised devices"],
          )

        case .onboarding(.happyPath(.confirmMinorDevice)):
          ButtonScreenView(
            text: "Is this a child’s (under 18) device?",
            primary: self.btn(text: "Yes, under 18", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.confirmParentIsOnboarding)):
          ButtonScreenView(
            text: "Are you the parent or guardian?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.happyPath(.confirmInAppleFamily)):
          ButtonScreenView(
            text: "Apple also requires that the child’s device be part of an Apple Family. Is the Apple Account for this device already in an Apple Family?",
            primary: self.btn(text: "Yes, it’s in an Apple Family", .primary),
            secondary: self.btn(text: "No", .secondary),
            tertiary: self.btn(text: "I’m not sure", .tertiary),
          )

        case .onboarding(.happyPath(.explainTwoInstallSteps)):
          ButtonScreenView(
            text: "Next we’ll authorize and install the content filter. It takes TWO steps, both of which are required.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.explainAuthWithParentAppleAccount)):
          ButtonScreenView(
            text: "For the first step, you’ll authorize Gertrude to access Screen Time using YOUR Apple ID (the parent/guardian, not the child’s).",
            primary: self.btn(text: "Got it, next", .primary),
          )

        case .onboarding(.happyPath(.dontGetTrickedPreAuth)):
          ButtonScreenView(
            text: "Don’t get tricked! Be sure to click “Continue”, even though it looks like you’re supposed to click “Don’t Allow”.",
            primary: self.btn(text: "Got it, next", .primary, animate: false, async: true),
            image: "AllowScreenTimeAccess",
          )

        case .onboarding(.happyPath(.explainInstallWithDevicePasscode)):
          ButtonScreenView(
            text: "Great! Half way there. In the next step, use the passcode of THIS DEVICE (the one you’re holding), not your own.",
            primary: self.btn(text: "Got it, next", .primary),
          )

        case .onboarding(.happyPath(.dontGetTrickedPreInstall)):
          ButtonScreenView(
            text: "Again, don’t get tricked! Be sure to click “Allow”, even though it looks like you’re supposed to click “Don’t Allow”.",
            primary: self.btn(text: "Got it, next", .primary, animate: false, async: true),
            image: "AllowContentFilter",
          )

        case .onboarding(.happyPath(.offerAccountConnect)):
          ButtonScreenView(
            text: self.store.onboarding.connectFeature.offerScreenText ??
              "You can connect this device to a Gertrude parent account for more controls and features.",
            primary: self.btn(text: "No thanks", .primary),
            secondary: self.btn(
              text: self.store.onboarding.connectFeature.offerScreenConnectBtnText ??
                "Connect to account",
              .secondary,
              animate: false,
            ),
            tertiary: self.btn(text: "Tell me more", .tertiary),
          )

        case .onboarding(.happyPath(.explainAccountConnect)):
          ButtonScreenView(
            text: self.store.onboarding.connectFeature.explainScreenText ??
              "Connecting to a Gertrude account allows the parent to modify settings remotely after installation, safe-list websites in Safari, and more. It is not required, all the core blocking features will always work without an account or payment.",
            primary: self.btn(text: "Back", .primary),
            secondary: .init(text: "Read the blog post", type: .link(.connect), animate: false),
          )

        case .onboarding(.happyPath(.connectSuccess)):
          ButtonScreenView(
            text: "Success! This device is now connected to your Gertrude parent account.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.happyPath(.optOutBlockGroups)):
          ChooseWhatToBlockView(
            deselectedGroups: self.store.disabledBlockGroups,
            onGroupToggle: { self.store.send(.interactive(.blockGroupToggled($0))) },
            onDone: { self.store.send(.interactive(.onboardingBtnTapped(.primary, "Done"))) },
          )

        case .onboarding(.happyPath(.promptClearCache)):
          ButtonScreenView(
            text: "Gertrude is now blocking new content, like when a new and unique search is made for GIFs. But content ALREADY VIEWED will still be visible unless we clear the cache.",
            primary: self.btn(text: "Clear the cache", .primary),
            secondary: self.btn(text: "No need, skip", .secondary),
          )

        case .onboarding(.happyPath(.requestAppStoreRating)):
          ButtonScreenView(
            text: "All set! But, if you’d like to help other parents protect their kids, tap to give us a rating on the App Store.",
            primary: self.btn(text: "Give a rating", .primary),
            secondary: self.btn(text: "Leave a review", .secondary),
            tertiary: self.btn(text: "No thanks", .tertiary),
            screenType: .info,
          )

        case .onboarding(.happyPath(.doneQuit)):
          FinishedView()

        case .onboarding(.authFail(.invalidAccount(.letsFigureThisOut))):
          ButtonScreenView(
            text: "Hmmm... Something didn’t work right, let’s get to the bottom of it.",
            primary: self.btn(text: "Next", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))):
          ButtonScreenView(
            text: "It might be that the Apple Account is not part of an Apple Family. Apple won’t allow the installation if it’s not. Is the Apple Account a member of an Apple Family?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
            tertiary: self.btn(text: "I’m not sure", .tertiary),
            screenType: .error,
          )

        case .onboarding(.authFail(.invalidAccount(.confirmIsMinor))):
          ButtonScreenView(
            text: "Are you sure the birthday on the Apple Account is for someone under 18?\n\nGood to know: Apple does permit the birthday to be changed one time.",
            primary: self.btn(text: "Age is 18 or over", .primary),
            secondary: self.btn(text: "Age is under 18", .secondary),
            screenType: .error,
          )

        case .onboarding(.authFail(.invalidAccount(.unexpected))):
          ButtonScreenView(
            text: "Well gosh, we’re not sure what’s wrong then. Try powering the device off completely, then start the installation again. If you get here again, please contact us for more help using the link below.",
            primary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.authFail(.authCanceled)):
          ButtonScreenView(
            text: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we’ll just try again.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.authFail(.restricted)):
          ButtonScreenView(
            text: "A restriction is preventing Gertrude from being installed. Is this device enrolled in mobile device management (MDM) by an organization or school? If so, try again on a device not managed by MDM.",
            primary: .init(text: "Contact support", type: .link(.support), animate: false),
            secondary: self.btn(text: "Start over", .secondary),
            screenType: .error,
          )

        case .onboarding(.authFail(.authConflict)):
          ButtonScreenView(
            text: "We got an error that there was a conflict with another parental controls app. If you know what that might be and can remove it, do so and then try again.",
            primary: self.btn(text: "Done, continue", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.networkError)):
          ButtonScreenView(
            text: "Hmmm.. Are you sure you’re connected to the internet? Double-check and try again when you’re online.",
            primary: self.btn(text: "Try again", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.passcodeRequired)):
          ButtonScreenView(
            text: "Sorry, Apple won’t let us install unless this device has a passcode set. Go to the Settings app and set one up, then try again.",
            primary: self.btn(text: "Try again", .primary),
            screenType: .error,
          )

        case .onboarding(.authFail(.unexpected)):
          ButtonScreenView(
            text: "Shucks, something went wrong, but we’re not exactly sure what. Please try again, and if you end up here again, contact us for help.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.installFail(.permissionDenied)):
          ButtonScreenView(
            text: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we’ll just try again.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.installFail(.other)):
          ButtonScreenView(
            text: "Shucks, something went wrong, but we’re not exactly sure what. Please try again, and if you end up here again, contact us for help.",
            primary: self.btn(text: "Try again", .primary),
            secondary: .init(text: "Contact us", type: .link(.support), animate: false),
            screenType: .error,
          )

        case .onboarding(.onParentDeviceFail):
          ButtonScreenView(
            text: "Gertrude must be installed on the device you want to protect, not on a parent or guardian’s device. Delete the app and start over by installing it on the device you want to protect.",
          )

        case .onboarding(.childIsOnboardingFail):
          ButtonScreenView(
            text: "Setting up Gertrude requires your parent or guardian. Give your device to them so they can finish the setup.",
            primary: self.btn(text: "Done, continue", .primary),
          )

        case .onboarding(.major(.explainHarderButPossible)):
          ButtonScreenView(
            text: "Getting this app working on the device of someone over 18 is harder, but still possible. We’ll walk you through all the steps.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.major(.askSelfOrOtherIsOnboarding)):
          ButtonScreenView(
            text: "Is this your device, or are you setting up Gertrude for someone else?",
            primary: self.btn(text: "I’m helping someone else", .secondary),
            secondary: self.btn(text: "This is my device", .tertiary),
            primaryLooksLikeSecondary: true,
          )

        case .onboarding(.major(.askIfOtherIsParent)):
          ButtonScreenView(
            text: "Are you the parent or guardian of the person who owns this device?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.major(.explainFixAccountTypeEasyWay)):
          ButtonScreenView(
            text: "The easiest way to make this work is to get this device signed into an Apple Account that is part of an Apple Family, with a birthday less than 18 years ago. If you can, do that now, then start the installation again, and the setup will be easy.\n\nHow can you do this?",
            primary: self.btn(text: "Done", .primary),
            secondary: self.btn(text: "Is there another way?", .secondary),
            listItems: [
              "Perhaps there is a younger sibling whose account could be used?",
              "Apple does permit changing the birthday one time.",
              "Anyone can create an Apple Family, and invite others to join.",
            ],
          )

        case .onboarding(.major(.askIfOwnsMac)):
          ButtonScreenView(
            text: "Do you own a Mac computer?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
          )

        case .onboarding(.major(.askIfInAppleFamily)),
             .onboarding(.major(.explainAppleFamily)):
          ButtonScreenView(
            text: "Are you in an Apple Family, or could you join one?",
            primary: self.btn(text: "Yes", .primary),
            secondary: self.btn(text: "No", .secondary),
            tertiary: self.btn(text: "What’s an Apple Family?", .tertiary, animate: false),
          )
          .sheet(isPresented: self.explainFamilyPresented) {
            ZStack {
              Color(self.cs, light: .clear, dark: .black).ignoresSafeArea(edges: .all)
              ButtonScreenView(
                text: "An Apple Family group allows sharing of apps and services. There’s no cost, and it’s easy to set one up. You would need someone else to start a group (if they didn’t already have one) and then invite you to join.",
                primary: .init(text: "Instructions", type: .link(.appleFamily), animate: false),
                secondary: self.btn(text: "Continue", .primary, animate: false),
              )
            }
            .presentationDetents([.fraction(0.9)])
          }

        case .onboarding(.appleFamily(.explainRequiredForFiltering)):
          ButtonScreenView(
            text: "Sorry, Apple doesn’t allow a content blocker to be installed on a device that’s not in an Apple Family.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.explainSetupFreeAndEasy)):
          ButtonScreenView(
            text: "Luckily, setting up an Apple family only takes a few minutes, and it’s free.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.howToSetupAppleFamily)):
          ButtonScreenView(
            text: "You’ll need to start the setup on your iPhone or Mac.",
            primary: .init(text: "Instructions", type: .link(.appleFamily), animate: false),
            secondary: .init(
              text: "Send me the info",
              type: .share(URL.appleFamily.absoluteString),
              animate: false,
            ),
            tertiary: self.btn(text: "Done, continue", .tertiary),
          )

        case .onboarding(.appleFamily(.explainWhatIsAppleFamily)):
          ButtonScreenView(
            text: "An Apple Family group allows sharing of apps and services, plus it gives parents additional controls over their kids devices. There’s no cost, and it’s easy to set one up.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.appleFamily(.checkIfInAppleFamily)):
          ButtonScreenView(
            text: "You can check if you’re already setup by opening the “Settings” app on this device. If you see a “Family” section right below the Apple Account name and picture, you’re already set.",
            primary: self.btn(text: "Yes, in a family", .primary),
            secondary: self.btn(text: "Not in a family yet", .secondary),
          )

        case .onboarding(.supervision(.intro)):
          ButtonScreenView(
            text: "The other way to get Gertrude working is to put this device into “supervised mode.”",
            primary: self.btn(text: "What’s that?", .primary),
          )

        case .onboarding(.supervision(.explainSupervision)):
          ButtonScreenView(
            text: "Supervised mode is most often used for devices owned by schools or businesses, and it enables many additional options and restrictions.",
            primary: self.btn(text: "Next", .primary),
          )

        case .onboarding(.supervision(.explainNeedFriendWithMac)):
          ButtonScreenView(
            text:
            "For supervised mode, you’ll need a trusted friend with a Mac computer to be your administrator. They don’t have to live with you, but they will need physical access to your device to set it up and from time to time after that.",
            primary: self.btn(text: "I’ve got someone", .primary),
            secondary: self.btn(text: "I don’t have anyone", .secondary),
          )

        case .onboarding(.supervision(.explainRequiresEraseAndSetup)):
          ButtonScreenView(
            text: "Setting up supervised mode requires temporarily erasing the device, an administrator with a Mac computer, and about an hour of work. You can restore the content and settings afterwards.",
            primary: self.btn(text: "Show me how", .primary),
            secondary: self.btn(text: "No thanks", .secondary),
          )

        case .onboarding(.supervision(.instructions)):
          ButtonScreenView(
            text: "We have a tutorial and a step-by-step video to guide you through the process.",
            primary: .init(text: "Instructions", type: .link(.supervisionTutorial), animate: false),
            secondary: .init(
              text: "Send the link",
              type: .share(URL.supervisionTutorial.absoluteString),
              animate: false,
            ),
          )

        case .onboarding(.supervision(.sorryNoOtherWay)):
          ButtonScreenView(
            text: "Sorry, looks like Gertrude won’t be able to help you with this device. Unfortunately we can only install the content blocker when Apple allows us, which is only for a child’s device or a supervised device.",
            primary: .init(text: "Contact support", type: .link(.support), animate: false),
            secondary: self.btn(text: "Start over", .secondary),
            primaryLooksLikeSecondary: true,
          )

        case .supervisionSuccessFirstLaunch:
          ButtonScreenView(
            text: "Excellent! Looks like you’ve installed Gertrude under Supervised mode. Just a couple steps to get you all set up.",
            primary: self.btn(text: "Next", .primary),
          )

        case .running(state: let state):
          RunningView(store: self.store, childName: state.childName)
            .onShake { self.store.send(.interactive(.receivedShake)) }
        }
      }
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.connectAccount,
      action: \.destination.connectAccount,
    )) {
      ConnectingView(store: $0)
    }
    .sheet(item: self.$store.scope(
      state: \.destination?.info,
      action: \.destination.info,
    )) { store in
      InfoView(store: store)
        .onAppear { store.send(.sheetPresented) }
        .onShake { store.send(.receivedShake) }
    }
  }

  var explainFamilyPresented: Binding<Bool> {
    .init(
      get: { self.store.screen == .onboarding(.major(.explainAppleFamily)) },
      set: { presented in if !presented { self.store.send(.interactive(.sheetDismissed)) } },
    )
  }

  func btn(
    text: String,
    _ type: ButtonType,
    animate: Bool = true,
    async: Bool = false,
  ) -> ButtonScreenView.Config {
    .init(text, animate: animate, asyncAction: async) {
      switch type {
      case .primary:
        self.store.send(.interactive(.onboardingBtnTapped(.primary, text)))
      case .secondary:
        self.store.send(.interactive(.onboardingBtnTapped(.secondary, text)))
      case .tertiary:
        self.store.send(.interactive(.onboardingBtnTapped(.tertiary, text)))
      }
    }
  }

  enum ButtonType {
    case primary
    case secondary
    case tertiary
  }
}

extension URL {
  static let support = URL(string: "https://gertrude.app/iosapp-contact")!
  static let connect = URL(string: "https://gertrude.app/iosapp-connect")!
  static let supervisionTutorial = URL(string: "https://gertrude.app/iosapp-supervise")!
  static let appleFamily = URL(string: "https://gertrude.app/iosapp-apple-fam")!
}

#Preview {
  AppView(
    store: Store(initialState: IOSReducer.State()) {
      IOSReducer()
    },
  )
}
