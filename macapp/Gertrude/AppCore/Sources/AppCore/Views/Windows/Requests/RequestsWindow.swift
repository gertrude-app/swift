import SharedCore
import SwiftUI

struct RequestsWindow: View, StoreView {
  static let MIN_WIDTH: CGFloat = 900
  static let MIN_HEIGHT: CGFloat = 500

  @EnvironmentObject var store: AppStore

  var viewState: RequestsWindowState { store.state.requestsWindow }
  var selected: Set<UUID> { viewState.selectedRequests }
  var showingSubmitResult: Bool { viewState.unlockRequestFetchState.isSubmitted }

  var body: some View {
    AccountStatusAware {
      VStack(spacing: 0) {
        FilterableRequests()
        if selected.count > 0 || showingSubmitResult {
          SubmitUnlockRequest()
        }
      }
    }
    .frame(minWidth: Self.MIN_WIDTH, minHeight: Self.MIN_HEIGHT)
  }
}

#if DEBUG
  struct RequestsWindow_Previews: PreviewProvider, GertrudeProvider {
    static var initializeState: StateCustomizer? = { state in
      let mocks = make(20, FilterDecision.mock)
      state.requestsWindow.requests = mocks
      state.requestsWindow.selectedRequests = mocks
        .first { $0.verdict == .block }
        .map { [$0.id] }!
    }

    static var cases: [(inout AppState) -> Void] = [
      { $0.colorScheme = .light },
      { state in
        state.accountStatus = .needsAttention
        state.requestsWindow.selectedRequests = []
      },
      { $0.colorScheme = .dark },
    ]

    static var previews: some View {
      ForEach(allPreviews) {
        RequestsWindow().store($0).requestsPreview()
      }
    }
  }
#endif
