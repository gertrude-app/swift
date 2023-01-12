import SwiftUI

struct FilterSuspensionRequest: View, StoreView {
  private typealias Duration = RequestFilterSuspensionWindowState.Duration

  @EnvironmentObject var store: AppStore

  static let MIN_WIDTH: CGFloat = 500
  static let MIN_HEIGHT: CGFloat = 300

  var state: RequestFilterSuspensionWindowState {
    store.state.requestFilterSuspensionWindow
  }

  private var duration: Binding<Duration> {
    store.bind(\.requestFilterSuspensionWindow.duration) {
      .updateFilterSuspensionDuration($0)
    }
  }

  private var customDuration: Binding<String> {
    store.bind(\.requestFilterSuspensionWindow.customDuration) {
      .updateFilterSuspensionCustomDuration($0)
    }
  }

  private var comment: Binding<String> {
    store.bind(\.requestFilterSuspensionWindow.comment) {
      .updateFilterSuspensionComment($0)
    }
  }

  func Form() -> some View {
    Group {
      VStack(spacing: 10) {
        Text("Request Temporary Filter Suspension:")
          .bold()
        VStack(alignment: .leading, spacing: 7) {
          Text("Reason:").offset(x: 0, y: 4)
          TextEditor(text: comment)
            .padding(top: 4, right: 0, bottom: 4, left: 4)
            .background(darkMode ? Color(hex: 0x111111) : Color(hex: 0xEFEFEF))
            .frame(maxHeight: 80)
        }
        HStack {
          Picker("Requested duration:", selection: duration) {
            ForEach(Duration.allCases) { duration in
              Text(duration.rawValue).tag(duration)
            }
          }
        }

        if state.duration == .custom {
          HStack {
            Text("Custom duration:").padding(right: 18)
            TextField("", text: customDuration)
            Text("seconds")
          }
        }

        HStack {
          Spacer()
          Button(action: { store.send(.submitRequestFilterSuspensionClicked) }) {
            Image(systemName: "paperplane.fill")
            Text("Submit").offset(x: -2)
          }
        }
        .padding(top: 15)
      }
      .frame(maxWidth: 350)
    }
  }

  var body: some View {
    AccountStatusAware(size: .small) {
      Group {
        switch state.fetchState {
        case .fetching:
          Submitting()
        case .success:
          SuccessMessage("Filter suspension request submitted.")
        case .error(let msg):
          ErrorMessage(msg)
        case .waiting:
          Form()
        }
      }
      .frame(minWidth: Self.MIN_WIDTH, minHeight: Self.MIN_HEIGHT)
      .background(darkMode ? Color.black : Color.white)
    }
  }
}

struct FilterSuspensionRequest_Previews: PreviewProvider, GertrudeProvider {
  static var initializeState: StateCustomizer? = { _ in }

  static var cases: [(inout AppState) -> Void] = [
    { state in
      state.accountStatus = .inactive
    },
    { state in
      state.accountStatus = .needsAttention
    },
    { state in
      state.colorScheme = .dark
      state.requestFilterSuspensionWindow.comment = "English class starting"
    },
    { state in
      state.requestFilterSuspensionWindow.duration = .custom
      state.requestFilterSuspensionWindow.customDuration = "1234"
    },
    { state in
      state.requestFilterSuspensionWindow.fetchState = .fetching
    },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      FilterSuspensionRequest().store($0)
        .frame(width: FilterSuspensionRequest.MIN_WIDTH, height: FilterSuspensionRequest.MIN_HEIGHT)
    }
  }
}
