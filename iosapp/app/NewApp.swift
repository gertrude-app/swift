import ComposableArchitecture
import SwiftUI

@Reducer
struct NewApp {
  @ObservableState
  enum State {
    case happyPath_1
    case happyPath_2
    case happyPath_3

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
        self.store.send(.advanceTo(.happyPath_1))
      } secondary: {
        self.store.send(.advanceTo(.happyPath_1))
      }
    }
  }
}

#Preview {
  NewAppView(
    store: Store(
      initialState: NewApp.State.happyPath_1
    ) {
      NewApp()
    }
  )
}
