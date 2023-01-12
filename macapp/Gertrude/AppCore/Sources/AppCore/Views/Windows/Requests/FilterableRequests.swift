import SharedCore
import SwiftUI

struct FilterableRequests: View, StoreView {
  @EnvironmentObject var store: AppStore

  var state: RequestsWindowState { store.state.requestsWindow }
  var selected: Set<UUID> { state.selectedRequests }
  var requests: [FilterDecision] { state.requests }

  var filteredRequests: [FilterDecision] {
    requests
      .filter { req in
        if selected.contains(req.id) {
          return true
        }

        if state.filter.showBlockedRequestsOnly, req.verdict == .allow {
          return false
        }

        if state.filter.showTcpRequestsOnly, req.ipProtocol?.isTcp != true {
          return false
        }

        if state.filter.byText, state.filter.text != "" {
          return req.filterString.contains(state.filter.text.lowercased())
        }

        return true
      }
      .sorted { $0.createdAt > $1.createdAt }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(spacing: 20) {
        Button(action: { store.send(.requestsWindowClearRequestsClicked) }) {
          HStack(spacing: 6) {
            Image(systemName: "trash")
              .resizable()
              .frame(width: 11, height: 11)
              .foregroundColor(.red)
              .offset(x: 0, y: 0.5)
            Text("Clear Requests")
              .foregroundColor(Color.primary)
          }
        }
        Toggle("Blocks Only", isOn: store.bind(
          \.requestsWindow.filter.showBlockedRequestsOnly,
          { .requestsWindowSetFilterBlocksOnly($0) }
        ))
        Toggle("TCP Only", isOn: store.bind(
          \.requestsWindow.filter.showTcpRequestsOnly,
          { .requestsWindowSetFilterTcpOnly($0) }
        ))
        Toggle("Filter", isOn: store.bind(
          \.requestsWindow.filter.byText,
          { .requestsWindowSetFiltering($0) }
        ))
        if state.filter.byText {
          TextInput(text: store.bind(
            \.requestsWindow.filter.text,
            { .requestsWindowSetFilterText($0) }
          ))
        }
      }
      .padding(x: 12)
      .frame(height: 50)

      if filteredRequests.count == 0 {
        Text(requests.count == 0 ? "Waiting for requests..." : "No matching requests.")
          .foregroundColor(.secondary)
          .italic()
          .infinite()
          .background(darkMode ? Color.black : Color.white)
      } else {
        RequestsTable(requests: filteredRequests)
      }
    }
    .background(Color(hex: darkMode ? 0x000000 : 0xEEEEEE))
  }
}

#if DEBUG
  struct FilterableRequests_Previews: PreviewProvider, GertrudeProvider {
    static var cases: [(inout AppState) -> Void] = [
      { state in state.requestsWindow.requests = [] },
      { state in state.requestsWindow.requests = make(40, FilterDecision.mock) },
      { state in
        state.colorScheme = .dark
        state.requestsWindow.requests = make(40, FilterDecision.mock)
        state.requestsWindow.filter.byText = true
        state.requestsWindow.filter.text = "example.com"
      },
    ]

    static var previews: some View {
      ForEach(allPreviews) {
        FilterableRequests().store($0).requestsPreview()
      }
    }
  }
#endif
