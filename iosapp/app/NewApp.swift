import ComposableArchitecture
import SwiftUI

@Reducer
struct NewApp {
  @ObservableState
  enum State {
    case happyPath_1
    case happyPath_2
    case happyPath_3
    case happyPath_4
    case happyPath_5
    case happyPath_6
    case happyPath_7
    case happyPath_8
    case happyPath_9
    case happyPath_10
    case happyPath_11
    case happyPath_12
    case happyPath_13
    case happyPath_14
    case happyPath_15
    case happyPath_16
    case happyPath_17
    case happyPath_18
    case happyPath_19

    case errAuth_1_1
    case errAuth_1_2
    case errAuth_1_3
    case errAuth_1_4
    case errAuth_2
    case errAuth_3
    case errAuth_4
    case errAuth_5
    case errAuth_6
    case errAuth_7

    case errInstall_1
    case errInstall_2

    case alt_1
    case alt_2

    case major_1
    case major_2
    case major_3
    case major_4
    case major_5
    case major_6

    case family_1
    case family_2
    case family_3
    case family_4
    case family_5

    case supervised_1
    case supervised_2
    case supervised_3
    case supervised_4
    case supervised_5
    case supervised_6
    case supervised_7

    case running

    init() {
      self = .happyPath_1
    }
  }

  enum Action {
    case advanceTo(State)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .advanceTo(let position):
        state = position
        return .none
      }
    }
  }
}

struct NewAppView: View {
  let store: StoreOf<NewApp>

  @Environment(\.colorScheme) var cs
  @Environment(\.openURL) var openLink
  @State private var showFamilyExplanation = false

  let supportUrl = URL(string: "https://gertrude.app/contact")!

  var body: some View {
    switch self.store.state {
    case .happyPath_1:
      WelcomeView {
        self.store.send(.advanceTo(.happyPath_2))
      }

    case .happyPath_2:
      ButtonScreenView(
        text: "The setup usually takes about 5-8 minutes, but in some cases extra steps are required.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_3))
          },
          animate: true
        )
      )

    case .happyPath_3:
      ButtonScreenView(
        text: "Is this the device you want to protect?",
        primary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.happyPath_4))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.alt_1))
          },
          animate: true
        )
      )

    case .happyPath_4:
      ButtonScreenView(
        text: "Apple only allows Gertrude to do it's job on two kinds of devices:",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_5))
          },
          animate: true
        ),
        listItems: ["Devices used by children under 18", "Supervised devices"]
      )

    case .happyPath_5:
      ButtonScreenView(
        text: "Is this a child's (under 18) device?",
        primary: ButtonScreenView.Config(
          text: "Yes, under 18",
          type: .button {
            self.store.send(.advanceTo(.happyPath_6))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.major_1))
          },
          animate: true
        )
      )

    case .happyPath_6:
      ButtonScreenView(
        text: "Are you the parent or guardian?",
        primary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.happyPath_7))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.alt_2))
          },
          animate: true
        )
      )

    case .happyPath_7:
      ButtonScreenView(
        text: "Apple also requires that the child's device be part of an Apple Family. Is the Apple Account for this device already in an Apple Family?",
        primary: ButtonScreenView.Config(
          text: "Yes, it's in an Apple Family",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.family_1))
          },
          animate: true
        ),
        tertiary: ButtonScreenView.Config(
          text: "I'm not sure",
          type: .button {
            self.store.send(.advanceTo(.family_4))
          },
          animate: true
        )
      )

    case .happyPath_8:
      ButtonScreenView(
        text: "Next we'll authorize and install the content filter. It takes two steps, both of which are required.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_9))
          },
          animate: true
        )
      )

    case .happyPath_9:
      ButtonScreenView(
        text: "For the first step, you'll authorize Gertrude to access Screen Time using your Apple ID (the parent/guardian, not the child's).",
        primary: ButtonScreenView.Config(
          text: "Got it, next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_10))
          },
          animate: true
        )
      )

    case .happyPath_10:
      ButtonScreenView(
        text: "Don't get tricked! Be sure to click \"Allow\", even though it looks like you're supposed to click\"Don't Allow\".",
        primary: ButtonScreenView.Config(
          text: "Got it, next",
          type: .button {
            // TODO: this might go to errAuth
            self.store.send(.advanceTo(.happyPath_11))
          },
          animate: true
        ),
        image: "AllowContentFilter"
      )

    case .happyPath_11:
      ButtonScreenView(
        text: "Great! Half way there. In the next step, use the passcode of this device (the one you're holding), not your own.",
        primary: ButtonScreenView.Config(
          text: "Got it, next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_12))
          },
          animate: true
        )
      )

    case .happyPath_12:
      ButtonScreenView(
        text: "Again, don't get tricked! Be sure to click \"Continue\", even though it looks like you're supposed to click\"Don't Allow\".",
        primary: ButtonScreenView.Config(
          text: "Got it, next",
          type: .button {
            // TODO: this might go to errInstall
            self.store.send(.advanceTo(.happyPath_13))
          },
          animate: true
        ),
        image: "AllowScreenTimeAccess"
      )

    case .happyPath_13:
      ChooseWhatToBlockView {
        self.store.send(.advanceTo(.happyPath_14))
      }

    case .happyPath_14:
      ButtonScreenView(
        text: "Gertrude is now blocking new content, like when a new and unique search is made for GIFs. But content already viewed will still be visible unless we clear the cache.",
        primary: ButtonScreenView.Config(
          text: "Clear the cache",
          type: .button {
            // TODO: could go straight to HP.16
            self.store.send(.advanceTo(.happyPath_15))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No need, skip",
          type: .button {
            self.store.send(.advanceTo(.happyPath_18))
          }, animate: true
        )
      )

    case .happyPath_15:
      ButtonScreenView(
        text: "Clearing the cache uses a lot of battery; we recommend you plug in the device now.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_16))
          },
          animate: true
        )
      )

    case .happyPath_16:
      ClearingCacheView()

    case .happyPath_17:
      ButtonScreenView(
        text: "Done! Previously downloaded GIFs should be gone!",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_18))
          },
          animate: true
        )
      )

    case .happyPath_18:
      ButtonScreenView(
        text: "All set! But, if you'd like to help other parents protect their kids, tap to give us a rating on the App Store.",
        primary: ButtonScreenView.Config(
          text: "Give a rating",
          type: .button {
            self.store.send(.advanceTo(.happyPath_19))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No thanks",
          type: .button {
            self.store.send(.advanceTo(.happyPath_19))
          },
          animate: true
        ),
        screenType: .info
      )

    case .happyPath_19:
      FinishedView()

    case .errAuth_1_1:
      ButtonScreenView(
        text: "Hmmm... Something didn't work right, let's get to the bottom of it.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.errAuth_1_2))
          },
          animate: true
        ),
        screenType: .error
      )

    case .errAuth_1_2:
      ButtonScreenView(
        text: "It might be that the Apple Account is not part of an Apple Family. Apple won't allow the installation if it's not. Is the Apple Account a member of an Apple Family?",
        primary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.errAuth_1_3))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.family_2))
          },
          animate: true
        ),
        tertiary: ButtonScreenView.Config(
          text: "I'm not sure",
          type: .button {
            self.store.send(.advanceTo(.family_4))
          },
          animate: true
        ),
        screenType: .error
      )

    case .errAuth_1_3:
      ButtonScreenView(
        text: "Are you sure the birthday on the Apple Account is for someone under 18?\n\nGood to know: Apple does permit the birthday to be changed one time.",
        primary: ButtonScreenView.Config(
          text: "Age is 18 or over",
          type: .button {
            self.store.send(.advanceTo(.major_1))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Age is under 18",
          type: .button {
            self.store.send(.advanceTo(.errAuth_1_4))
          },
          animate: true
        ),
        screenType: .error
      )

    case .errAuth_1_4:
      ButtonScreenView(
        text: "Well gosh, we're not sure what's wrong then. Try powering the device off completely, then start the installation again. If you get here again, please contact us for more help using the link below.",
        primary: ButtonScreenView.Config(
          text: "Contact us",
          type: .link(self.supportUrl),
          animate: false
        ),
        screenType: .error
      )

    case .errAuth_2:
      ButtonScreenView(
        text: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we'll just try again.",
        primary: ButtonScreenView.Config(
          text: "Try again",
          type: .button {
            self.store.send(.advanceTo(.happyPath_9))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Contact us",
          type: .link(self.supportUrl),
          animate: false
        ),
        screenType: .error
      )

    case .errAuth_3:
      ButtonScreenView(
        text: "A restriction is preventing Gertrude from being installed. Is this device is enrolled in mobile device management (MDM) by an organization or school? If so, try again on a device not managed by MDM.",
        primary: ButtonScreenView.Config(
          text: "Contact support",
          type: .link(self.supportUrl),
          animate: false
        ),
        screenType: .error
      )

    case .errAuth_4:
      ButtonScreenView(
        text: "We got an error that there was a conflict with another parental controls app. If you know what that might be and can remove it, do so and then try again.",
        primary: ButtonScreenView.Config(
          text: "Done, continue",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        screenType: .error
      )

    case .errAuth_5:
      ButtonScreenView(
        text: "Hmmm.. Are you sure you're connected to the internet? Double-check and try again when you're online.",
        primary: ButtonScreenView.Config(
          text: "Try again",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        screenType: .error
      )

    case .errAuth_6:
      ButtonScreenView(
        text: "Sorry, Apple won't let us install unless this device has a passcode set. Go to the Settings app and set one up, then try again.",
        primary: ButtonScreenView.Config(
          text: "Try again",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        screenType: .error
      )

    case .errAuth_7:
      ButtonScreenView(
        text: "Shucks, something went wrong, but we're not exactly sure what. Please try again, and if you end up here again, contact us for help.",
        primary: ButtonScreenView.Config(
          text: "Try again",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Contact us",
          type: .link(self.supportUrl),
          animate: false
        ),
        screenType: .error
      )

    case .errInstall_1:
      ButtonScreenView(
        text: "Whoops! Looks like you either clicked the wrong button, or canceled the process mid-way. No problem, we'll just try again.",
        primary: ButtonScreenView.Config(
          text: "Try again",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Contact us",
          type: .link(self.supportUrl),
          animate: false
        ),
        screenType: .error
      )

    case .errInstall_2:
      ButtonScreenView(
        text: "Shucks, something went wrong, but we're not exactly sure what. Please try again, and if you end up here again, contact us for help.",
        primary: ButtonScreenView.Config(
          text: "Try again",
          type: .button {
            self.store.send(.advanceTo(.happyPath_8))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Contact us",
          type: .link(self.supportUrl),
          animate: false
        ),
        screenType: .error
      )

    case .alt_1:
      ButtonScreenView(
        text: "Gertrude must be installed on the device you want to protect, not on a parent or guardian's device. Delete the app and start over by installing it on the device you want to protect."
      )

    case .alt_2:
      ButtonScreenView(
        text: "Setting up Gertrude requires your parent or guardian. Give your device to them so they can finish the setup.",
        primary: ButtonScreenView.Config(
          text: "Done, continue",
          type: .button {
            self.store.send(.advanceTo(.happyPath_1))
          },
          animate: true
        )
      )

    case .major_1:
      ButtonScreenView(
        text: "Getting this app working on the device of someone over 18 is harder, but still possible. We'll walk you through all the steps.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.major_2))
          },
          animate: true
        )
      )

    case .major_2:
      ButtonScreenView(
        text: "Is this your device, or are you setting up Gertrude for someone else?",
        primary: ButtonScreenView.Config(
          text: "I'm helping someone else",
          type: .button {
            self.store.send(.advanceTo(.major_3))

          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "This is my device",
          type: .button {
            self.store.send(.advanceTo(.major_6))
          },
          animate: true
        ),
        primaryLooksLikeSecondary: true
      )

    case .major_3:
      ButtonScreenView(
        text: "Are you the parent or guardian of the person who owns this device?",
        primary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.major_4))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.major_5))
          },
          animate: true
        )
      )

    case .major_4:
      ButtonScreenView(
        text: "The easiest way to make this work is to get this device signed into an Apple Account that is part of an Apple Family, with a birthday less than 18 years ago. If you can, do that now, then start the installation again, and the setup will be easy.\n\nHow can you do this?",
        primary: ButtonScreenView.Config(
          text: "Done",
          type: .button {
            self.store.send(.advanceTo(.happyPath_5))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Is there another way?",
          type: .button {
            self.store.send(.advanceTo(.major_5))
          },
          animate: true
        ),
        listItems: [
          "Perhaps there is a younger sibling whose account could be used?",
          "Apple does permit changing the birthday one time.",
          "Anyone can create an Apple Family, and invite others to join.",
        ]
      )

    case .major_5:
      ButtonScreenView(
        text: "Do you own a Mac computer?",
        primary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.supervised_1))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.supervised_1))
          },
          animate: true
        )
      )

    case .major_6:
      ButtonScreenView(
        text: "Are you in an Apple Family, or could you join one?",
        primary: ButtonScreenView.Config(
          text: "Yes",
          type: .button {
            self.store.send(.advanceTo(.major_4))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No",
          type: .button {
            self.store.send(.advanceTo(.supervised_1))
          },
          animate: true
        ),
        tertiary: ButtonScreenView.Config(
          text: "What's an Apple Family?",
          type: .button {
            self.showFamilyExplanation = true
          },
          animate: false
        )
      )
      .sheet(isPresented: self.$showFamilyExplanation) {
        ZStack {
          Color(cs, light: .clear, dark: .black).ignoresSafeArea(edges: .all)
          ButtonScreenView(
            text: "An Apple Family group allows sharing of apps and services. There's no cost, and it's easy to set one up. You would need someone else to start a group (if they didn't already have one) and then invite you to join.",
            primary: ButtonScreenView.Config(
              text: "Instructions",
              type: .link(URL(string: "https://support.apple.com/en-us/108380")!),
              animate: false
            ),
            secondary: ButtonScreenView.Config(
              text: "Continue",
              type: .button {
                self.store.send(.advanceTo(.family_2))
              },
              animate: true
            )
          )
        }
      }

    case .family_1:
      ButtonScreenView(
        text: "Sorry, Apple doesn't allow a content blocker to be installed on a device that's not in an Apple Family.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.family_2))
          },
          animate: true
        )
      )

    case .family_2:
      ButtonScreenView(
        text: "Luckily, setting up an Apple family only takes a few minutes, and it's free.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.family_3))
          },
          animate: true
        )
      )

    case .family_3:
      ButtonScreenView(
        text: "You'll need to start the setup on your iPhone or Mac.",
        primary: ButtonScreenView.Config(
          text: "Instructions",
          type: .link(URL(string: "https://support.apple.com/en-us/108380")!),
          animate: false
        ),
        secondary: ButtonScreenView.Config(
          text: "Send me the info",
          type: .share("https://support.apple.com/en-us/108380"),
          animate: false
        ),
        tertiary: ButtonScreenView.Config(
          text: "Done, continue",
          type: .button {
            self.store.send(.advanceTo(.happyPath_7))
          },
          animate: true
        )
      )

    case .family_4:
      ButtonScreenView(
        text: "An Apple Family group allows sharing of apps and services, plus it gives parents additional controls over their kids devices. There's no cost, and it's easy to set one up.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.family_2))
          },
          animate: true
        )
      )

    case .family_5:
      ButtonScreenView(
        text: "You can check if you're already setup by opening the \"Settings\" app on this device. If you see a \"Family\" section right below the Apple Account name and picture, you're already set.",
        primary: ButtonScreenView.Config(
          text: "Yes, in a family",
          type: .button {
            self.store.send(.advanceTo(.happyPath_7))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "Not in a family yet",
          type: .button {
            self.store.send(.advanceTo(.family_2))
          },
          animate: true
        )
      )

    case .supervised_1:
      ButtonScreenView(
        text: "The other way to get Gertrude working is to put this device into supervised mode.",
        primary: ButtonScreenView.Config(
          text: "What's that?",
          type: .button {
            self.store.send(.advanceTo(.supervised_1))
          },
          animate: true
        )
      )

    case .supervised_2:
      ButtonScreenView(
        text: "Supervised mode is most often used for devices owned by schools or businesses, and it enables many additional options and restrictions.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            // TODO: might go to .supervised_4
            self.store.send(.advanceTo(.supervised_3))
          },
          animate: true
        )
      )

    case .supervised_3:
      ButtonScreenView(
        text: "For supervised mode, you'll need a trusted friend with a Mac computer to be your administrator. They don't have to live with you, but they will need physical access to your device to set it up and from time to time after that.",
        primary: ButtonScreenView.Config(
          text: "I've got someone",
          type: .button {
            self.store.send(.advanceTo(.supervised_4))

          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "I don't have anyone",
          type: .button {
            self.store.send(.advanceTo(.supervised_6))

          },
          animate: true
        )
      )

    case .supervised_4:
      ButtonScreenView(
        text: "Setting up supervised mode requires temporarily erasing the device, an administrator with a Mac computer, and about an hour of work. You can restore the content and settings afterwards.",
        primary: ButtonScreenView.Config(
          text: "Show me how",
          type: .button {
            self.store.send(.advanceTo(.supervised_5))
          },
          animate: true
        ),
        secondary: ButtonScreenView.Config(
          text: "No thanks",
          type: .button {
            self.store.send(.advanceTo(.supervised_6))
          },
          animate: true
        )
      )

    case .supervised_5:
      ButtonScreenView(
        text: "We have a tutorial and a step-by-step video to guide you through the process.",
        primary: ButtonScreenView.Config(
          text: "Instructions",
          type: .link(URL(string: "TODO")!),
          animate: false
        ),
        secondary: ButtonScreenView.Config(
          text: "Send the link",
          type: .share("TODO"),
          animate: false
        )
      )

    case .supervised_6:
      ButtonScreenView(
        text: "Sorry, looks like Gertrude won't be able to help you with this device. Unfortunately we can only install the content blocker when Apple allows us, which is only for a child's device or a supervised device."
      )

    case .supervised_7:
      ButtonScreenView(
        text: "Excellent! Looks like you've installed Gertrude under Supervised mode. Just a couple steps to get you all set up.",
        primary: ButtonScreenView.Config(
          text: "Next",
          type: .button {
            self.store.send(.advanceTo(.happyPath_13))
          },
          animate: true
        )
      )

    case .running:
      RunningView()
    }
  }
}

#Preview {
  NewAppView(
    store: Store(
      initialState: .major_6
    ) {
      NewApp()
    }
  )
}
