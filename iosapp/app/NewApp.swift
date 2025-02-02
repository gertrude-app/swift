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
    case errAuth_5_1
    case errAuth_5_2
    case errAuth_6

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
    case major_7

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

  var body: some View {
    switch self.store.state {
    case .happyPath_1:
      WelcomeView {
        self.store.send(.advanceTo(.happyPath_2))
      }

    case .happyPath_2:
      ButtonScreenView(
        text: "The setup usually takes about 5-8 minutes, but in some cases extra steps are required.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.happyPath_3))
      }

    case .happyPath_3:
      ButtonScreenView(
        text: "Is this the device you want to protect?",
        primaryButtonText: "Yes",
        secondaryButtonText: "No"
      ) {
        self.store.send(.advanceTo(.happyPath_4))
      } secondary: {
        self.store.send(.advanceTo(.alt_1))
      }

    case .happyPath_4:
      ButtonScreenView(
        text: "Apple only allows Gertrude to do it's job on two kinds of devices:",
        buttonText: "Next",
        listItems: ["Devices used by children under 18", "Supervised devices"]
      ) {
        self.store.send(.advanceTo(.happyPath_5))
      }

    case .happyPath_5:
      ButtonScreenView(
        text: "Is this a child's (under 18) device?",
        primaryButtonText: "Yes, under 18",
        secondaryButtonText: "No"
      ) {
        self.store.send(.advanceTo(.happyPath_6))
      } secondary: {
        self.store.send(.advanceTo(.major_1))
      }

    case .happyPath_6:
      ButtonScreenView(
        text: "Are you the parent or guardian?",
        primaryButtonText: "Yes",
        secondaryButtonText: "No"
      ) {
        self.store.send(.advanceTo(.happyPath_7))
      } secondary: {
        self.store.send(.advanceTo(.alt_2))
      }

    case .happyPath_7:
      ButtonScreenView(
        text: "Apple also requires that the child's device be part of an Apple Family. Is the Apple Account for this device already in an Apple Family?",
        primaryButtonText: "Yes, it's in an Apple Family",
        secondaryButtonText: "No",
        tertiaryButtonText: "I'm not sure"
      ) {
        self.store.send(.advanceTo(.happyPath_8))
      } secondary: {
        self.store.send(.advanceTo(.family_1))
      } tertiary: {
        self.store.send(.advanceTo(.family_4))
      }

    case .happyPath_8:
      ButtonScreenView(
        text: "Next we'll authorize and install the content filter. It takes two steps, both of which are required.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.happyPath_9))
      }

    case .happyPath_9:
      ButtonScreenView(
        text: "For the first step, you'll authorize Gertrude to access Screen Time using your Apple ID (the parent/guardian, not the child's).",
        buttonText: "Got it, next"
      ) {
        self.store.send(.advanceTo(.happyPath_10))
      }

    case .happyPath_10:
      ButtonScreenView(
        text: "Don't get tricked! Be sure to click \"Allow\", even though it looks like you're supposed to click\"Don't Allow\".",
        buttonText: "Got it, next",
        image: "AllowContentFilter"
      ) {
        // TODO: this might go to errAuth
        self.store.send(.advanceTo(.happyPath_11))
      }

    case .happyPath_11:
      ButtonScreenView(
        text: "Great! Half way there. In the next step, use the passcode of this device (the one you're holding), not your own.",
        buttonText: "Got it, next"
      ) {
        self.store.send(.advanceTo(.happyPath_12))
      }

    case .happyPath_12:
      ButtonScreenView(
        text: "Again, don't get tricked! Be sure to click \"Continue\", even though it looks like you're supposed to click\"Don't Allow\".",
        buttonText: "Got it, next",
        image: "AllowScreenTimeAccess"
      ) {
        // TODO: this might go to errInstall
        self.store.send(.advanceTo(.happyPath_13))
      }

    case .happyPath_13:
      // TODO: this should be a totally custom screen
      ChooseWhatToBlockView {
        self.store.send(.advanceTo(.happyPath_14))
      }
      
    case .happyPath_14:
      ButtonScreenView(
        text: "Gertrude is now blocking new content, like when a new and unique search is made for GIFs. But content already viewed will still be visible unless we clear the cache.",
        primaryButtonText: "Clear the cache",
        secondaryButtonText: "No need, skip"
      ) {
        // TODO: could go straight to HP.16
        self.store.send(.advanceTo(.happyPath_15))
      } secondary: {
        self.store.send(.advanceTo(.happyPath_18))
      }

    case .happyPath_15:
      ButtonScreenView(
        text: "Clearing the cache uses a lot of battery; we recommend you plug in the device now.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.happyPath_16))
      }

    case .happyPath_16:
      // TODO: this should be a totally custom screen
      VStack {
        Text("Clearing cache...")
        Button("Move along") {
          self.store.send(.advanceTo(.happyPath_17))
        }
      }

    case .happyPath_17:
      ButtonScreenView(
        text: "Done! Previously downloaded GIFs should be gone!",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.happyPath_18))
      }

    case .happyPath_18:
      ButtonScreenView(
        text: "All set! But, if you'd like to help other parents protect their kids, tap to give us a rating on the App Store.",
        primaryButtonText: "Give a rating",
        secondaryButtonText: "No thanks",
        screenType: .info
      ) {
        self.store.send(.advanceTo(.happyPath_19))
      } secondary: {
        self.store.send(.advanceTo(.happyPath_19))
      }

    case .happyPath_19:
      // TODO: should be a totally custom screen
      Text("You're dunners!")

    case .errAuth_1_1:
      Text("todo")

    case .errAuth_1_2:
      Text("todo")

    case .errAuth_1_3:
      Text("todo")

    case .errAuth_1_4:
      Text("todo")

    case .errAuth_2:
      Text("todo")

    case .errAuth_3:
      Text("todo")

    case .errAuth_4:
      Text("todo")

    case .errAuth_5_1:
      Text("todo")

    case .errAuth_5_2:
      Text("todo")

    case .errAuth_6:
      Text("todo")

    case .errInstall_1:
      Text("todo")

    case .errInstall_2:
      Text("todo")

    case .alt_1:
      Text("todo")

    case .alt_2:
      ButtonScreenView(
        text: "Setting up Gertrude requires your parent or guardian. Give your device to them so they can finish the setup.",
        buttonText: "Done, continue"
      ) {
        self.store.send(.advanceTo(.happyPath_1))
      }

    case .major_1:
      ButtonScreenView(
        text: "Getting this app working on the device of someone over 18 is harder, but still possible. We'll walk you through all the steps.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.major_2))
      }

    case .major_2:
      ButtonScreenView(
        text: "Is this your device, or are you setting up Gertrude for someone else?",
        primaryButtonText: "I'm helping someone else",
        secondaryButtonText: "This is my device",
        primaryLooksLikeSecondary: true
      ) {
        self.store.send(.advanceTo(.major_3))
      } secondary: {
        self.store.send(.advanceTo(.major_6))
      }

    case .major_3:
      ButtonScreenView(
        text: "Are you the parent or guardian of the person who owns this device?",
        primaryButtonText: "Yes",
        secondaryButtonText: "No"
      ) {
        self.store.send(.advanceTo(.major_4))
      } secondary: {
        self.store.send(.advanceTo(.major_5))
      }

    case .major_4:
      ButtonScreenView(
        text: "The easiest way to make this work is to get this device signed into an Apple Account that is part of an Apple Family, with a birthday less than 18 years ago. If you can, do that now, then start the installation again, and the setup will be easy.\n\nHow can you do this?",
        primaryButtonText: "Done",
        secondaryButtonText: "Is there another way?",
        listItems: [
          "Perhaps there is a younger sibling whose account could be used?",
          "Apple does permit changing the birthday one time.",
          "Anyone can create an Apple Family, and invite others to join.",
        ]
      ) {
        self.store.send(.advanceTo(.happyPath_5))
      } secondary: {
        self.store.send(.advanceTo(.major_5))
      }

    case .major_5:
      ButtonScreenView(
        text: "Do you own a Mac computer?",
        primaryButtonText: "Yes",
        secondaryButtonText: "No"
      ) {
        self.store.send(.advanceTo(.supervised_1))
      } secondary: {
        self.store.send(.advanceTo(.supervised_1))
      }

    case .major_6:
      ButtonScreenView(
        text: "Are you in an Apple Family, or could you join one?",
        primaryButtonText: "Yes",
        secondaryButtonText: "No",
        tertiaryButtonText: "What's an Apple Family?"
      ) {
        self.store.send(.advanceTo(.major_4))
      } secondary: {
        self.store.send(.advanceTo(.supervised_1))
      } tertiary: {}

    case .major_7:
      Text("todo")

    case .family_1:
      ButtonScreenView(
        text: "Sorry, Apple doesn't allow a content blocker to be installed on a device that's not in an Apple Family.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.family_2))
      }

    case .family_2:
      ButtonScreenView(
        text: "Luckily, setting up an Apple family only takes a few minutes, and it's free.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.family_3))
      }

    case .family_3:
      ButtonScreenView(
        text: "You'll need to start the setup on your iPhone or Mac.",
        primaryButtonText: "Instructions",
        secondaryButtonText: "Send me the info",
        tertiaryButtonText: "Done, continue"
      ) {
        // TODO: link to https://support.apple.com/en-us/108380
      } secondary: {
        // TODO: share sheet
      } tertiary: {
        self.store.send(.advanceTo(.happyPath_7))
      }

    case .family_4:
      ButtonScreenView(
        text: "An Apple Family group allows sharing of apps and services, plus it gives parents additional controls over their kids devices. There's no cost, and it's easy to set one up.",
        buttonText: "Next"
      ) {
        self.store.send(.advanceTo(.family_2))
      }
      
    case .family_5:
      ButtonScreenView(
        text: "You can check if you're already setup by opening the \"Settings\" app on this device. If you see a \"Family\" section right below the Apple Account name and picture, you're already set.",
        primaryButtonText: "Yes, in a family",
        secondaryButtonText: "Not in a family yet"
      ) {
        self.store.send(.advanceTo(.happyPath_7))
      } secondary: {
        self.store.send(.advanceTo(.family_2))
      }

    case .supervised_1:
      ButtonScreenView(
        text: "The other way to get Gertrude working is to put this device into supervised mode.",
        buttonText: "What's that?"
      ) {
        self.store.send(.advanceTo(.supervised_1))
      }

    case .supervised_2:
      ButtonScreenView(
        text: "Supervised mode is most often used for devices owned by schools or businesses, and it enables many additional options and restrictions.",
        buttonText: "Next"
      ) {
        // TODO: might go to .supervised_4
        self.store.send(.advanceTo(.supervised_3))
      }

    case .supervised_3:
      ButtonScreenView(
        text: "For supervised mode, you'll need a trusted friend with a Mac computer to be your administrator. They don't have to live with you, but they will need physical access to your device to set it up and from time to time after that.",
        primaryButtonText: "I've got someone",
        secondaryButtonText: "I don't have anyone"
      ) {
        self.store.send(.advanceTo(.supervised_4))
      } secondary: {
        self.store.send(.advanceTo(.supervised_6))
      }

    case .supervised_4:
      ButtonScreenView(
        text: "Setting up supervised mode requires temporarily erasing the device, an administrator with a Mac computer, and about an hour of work. You can restore the content and settings afterwards.",
        primaryButtonText: "Show me how",
        secondaryButtonText: "No thanks"
      ) {
        self.store.send(.advanceTo(.supervised_5))
      } secondary: {
        self.store.send(.advanceTo(.supervised_6))
      }

    case .supervised_5:
      ButtonScreenView(
        text: "We have a tutorial and a step-by-step video to guide you through the process.",
        primaryButtonText: "Instructions",
        secondaryButtonText: "Send the link"
      ) {
        // TODO: link to docs
      } secondary: {
        // TODO: pop up share sheet
      }

    case .supervised_6:
      // TODO: custom screen
      Text("Sorry, looks like Gertrude won't be able to help you with this device. Unfortunately we can only install the content blocker when Apple allows us, which is only for a child's device or a supervised device.")

    case .supervised_7:
      // TODO: custom screen
      Text("Excellent! Looks like you've installed Gertrude under Supervised mode. Just a couple steps to get you all set up.")

    case .running:
      // TODO: custom screen
      Text("Gertude is blocking unwanted content. You can quit the app now, it will keep blocking even when not running.")
    }
  }
}

#Preview {
  NewAppView(
    store: Store(
      initialState: .happyPath_1
    ) {
      NewApp()
    }
  )
}
