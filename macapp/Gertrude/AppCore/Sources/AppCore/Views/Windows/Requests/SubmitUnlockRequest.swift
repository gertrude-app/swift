import SwiftUI

struct SubmitUnlockRequest: View, StoreView {
  @EnvironmentObject var store: AppStore

  var requestsWindow: RequestsWindowState {
    store.state.requestsWindow
  }

  var selected: Set<UUID> {
    requestsWindow.selectedRequests
  }

  var fetchState: FetchState<Void> {
    requestsWindow.unlockRequestFetchState
  }

  var form: some View {
    Group {
      ZStack {
        Circle().foregroundColor(.brandPurple).frame(width: 13, height: 15)
        Text("\(selected.count)")
          .font(.system(size: 9))
          .foregroundColor(.white)
      }
      .offset(x: 0, y: -4)
      Text("Send unlock request with explanation:")
        .offset(x: -9)
      HStack {
        TextEditor(text: store.bind(
          \.requestsWindow.unlockRequestText,
          { .updateUnlockRequestText($0) }
        ))
        .padding(top: 4, right: 0, bottom: 4, left: 4)
      }
      .background(darkMode ? Color(hex: 0x1E1E1E) : Color.white)
      .frame(height: 50, alignment: .center)
      .padding(right: 10)
      Button(action: { store.send(.submitUnlockRequestsClicked) }) {
        Image(systemName: "paperplane.fill")
        Text("Submit").offset(x: -2)
      }
    }
  }

  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      switch fetchState {
      case .fetching:
        Submitting()
      case .success:
        SuccessMessage("Unlock request submitted.")
      case .error(let msg):
        ErrorMessage(msg)
      case .waiting:
        form
      }
    }
    .padding()
    .infinite()
    .frame(height: 70)
    .background(Color(hex: darkMode ? 0x444444 : 0xDDDDDD))
  }
}

struct SubmitUnlockRequest_Previews: PreviewProvider, GertrudeProvider {
  static var initializeState: StateCustomizer? = { state in
    state.requestsWindow.selectedRequests = [UUID()]
    state.requestsWindow.unlockRequestFetchState = .waiting
    state.requestsWindow.unlockRequestText = "I need this for English, Dad"
    state.colorScheme = .light
  }

  static var cases: [(inout AppState) -> Void] = [
    { state in
      state.colorScheme = .light
    },
    { state in
      state.colorScheme = .dark
    },
    { state in
      state.requestsWindow.unlockRequestFetchState = .fetching
    },
    { state in
      state.requestsWindow.unlockRequestFetchState = .success(())
    },
    { state in
      state.colorScheme = .dark
      state.requestsWindow.unlockRequestFetchState = .success(())
    },
    { state in
      state.requestsWindow.unlockRequestFetchState = .error("Failed to fetch")
    },
    { state in
      state.colorScheme = .dark
      state.requestsWindow.unlockRequestFetchState = .error("Failed to fetch")
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      SubmitUnlockRequest().store($0).frame(minWidth: RequestsWindow.MIN_WIDTH)
    }
  }
}
