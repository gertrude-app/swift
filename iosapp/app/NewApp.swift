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
      VStack {
        Text("Success! We're nearly done. Gertrude is all set to block content. Take a moment to decide if there are any of these types of content that you don't want to block:")
        Button("Done, continue") {
          self.store.send(.advanceTo(.happyPath_14))
        }
      }

    case .happyPath_14:
      ButtonScreenView(
        text: "Gertrude is now blocking new content, like when a new and unique search is made for GIFs. But content already viewed will still be visible unless we clear the cache.",
        primaryButtonText: "Clear the cache",
        secondaryButtonText: "No need, skip"
      ) {
        // TODO: could go to HP.16
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
      Text("todo")
      
    case .major_1:
      Text("todo")
      
    case .major_2:
      Text("todo")
      
    case .major_3:
      Text("todo")
      
    case .major_4:
      Text("todo")
      
    case .major_5:
      Text("todo")
      
    case .major_6:
      Text("todo")
      
    case .major_7:
      Text("todo")
      
    case .family_1:
      Text("todo")
      
    case .family_2:
      Text("todo")
      
    case .family_3:
      Text("todo")
      
    case .family_4:
      Text("todo")
      
    case .supervised_1:
      Text("todo")
      
    case .supervised_2:
      Text("todo")
      
    case .supervised_3:
      Text("todo")
      
    case .supervised_4:
      Text("todo")
      
    case .supervised_5:
      Text("todo")
      
    case .supervised_6:
      Text("todo")
      
    case .supervised_7:
      Text("todo")
      
    case .running:
      Text("todo")
    }
  }
}

#Preview {
  NewAppView(
    store: Store(
      initialState: .happyPath_19
    ) {
      NewApp()
    }
  )
}

