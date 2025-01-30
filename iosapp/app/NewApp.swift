import ComposableArchitecture
import SwiftUI

@Reducer
struct NewApp {
  @ObservableState
  enum State {
    case happyPath_1
    case happyPath_2
    
    init () {
      self = .happyPath_1
    }
  }

  enum Action {
    case advanceTo(State)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .advanceTo(position):
        state = position
        return .none
      }
    }
  }
}

struct NewAppView: View {
  let store: StoreOf<NewApp>

  var body: some View {
    switch store.state {
    case .happyPath_1:
      WelcomeView() {
        store.send(.advanceTo(.happyPath_2))
      }
      
    case .happyPath_2:
      ButtonScreenView(text: "The setup usually takes about 5-8 minutes, but in some cases extra steps are required.", buttonText: "Next") {
        store.send(.advanceTo(.happyPath_1))
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
