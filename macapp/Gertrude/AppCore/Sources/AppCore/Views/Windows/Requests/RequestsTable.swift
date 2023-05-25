import AppKit
import Gertie
import SharedCore
import SwiftUI

struct RequestsTable: View, StoreView {
  @EnvironmentObject var store: AppStore

  var requests: [FilterDecision]
  var selected: Set<UUID> { store.state.requestsWindow.selectedRequests }

  func iconData(for request: FilterDecision) -> (name: String, color: Color, offset: CGFloat) {
    if selected.contains(request.id) {
      return (name: "lock.open.fill", color: .brandPurple, offset: 0)
    } else if request.verdict == .allow {
      return (name: "lock.open.fill", color: green, offset: 0)
    } else {
      return (name: "lock.fill", color: red, offset: -2.5)
    }
  }

  var body: some View {
    List(requests.indexed) { indexed in
      let req = indexed.indexed
      let (iconName, iconColor, iconOffset) = iconData(for: req)
      HStack {
        Image(systemName: iconName)
          .resizable()
          .scaledToFit()
          .frame(width: 16, height: 16)
          .foregroundColor(iconColor)
          .offset(x: iconOffset)
          .padding(right: 2)
          .onTapGesture {
            if req.verdict != .allow {
              store.send(.requestsWindowToggleSelected(req.id))
            }
          }

        Text(conciseTimeFormatter.string(from: req.createdAt))
          .foregroundColor(.secondary)
          .font(.system(size: 12, weight: .thin, design: .monospaced))

        Text((req.ipProtocol ?? .other(-1)).shortDescription)
          .foregroundColor(.secondary)
          .font(.system(size: 12, weight: .regular, design: .monospaced))
          .padding(x: 4)

        Text(req.displayUrl)
          .font(.system(size: 12, weight: .regular, design: .monospaced))

        Spacer()

        if let displayName = req.app?.displayName {
          Text(displayName.truncate(ifLongerThan: 20, with: "..."))
            .foregroundColor(.blue)
            .font(.system(size: 12, weight: .thin, design: .monospaced))
        } else {
          Text(req.app?.shortDescription ?? "")
            .foregroundColor(.purple)
            .font(.system(size: 10, weight: .thin, design: .monospaced))
        }

        Text(String(req.count))
          .foregroundColor(darkMode ? .secondary : .white)
          .font(.system(size: 9, weight: .thin, design: .monospaced))
          .frame(minWidth: 12)
          .padding(x: 3, y: 1)
          .background(Color(hex: 0x999999, alpha: darkMode ? 0.2 : 0.65))
          .cornerRadius(100)
      }
      .padding(x: 6, y: 5)
      .background(bandedRowBg(selected: selected.contains(req.id), alt: indexed.index % 2 == 0))
      .frame(height: 18)
    }
  }
}

#if DEBUG
  struct RequestsTable_Previews: PreviewProvider, GertrudeProvider {
    static var mockRequests = make(40, FilterDecision.mock)

    static var selected: Set<UUID>? {
      mockRequests.first { $0.verdict == .block }.map { [$0.id] }
    }

    static var cases: [(inout AppState) -> Void] = [
      { state in
        state.colorScheme = .light
        state.requestsWindow.selectedRequests = selected ?? []
      },
      { state in
        state.colorScheme = .dark
        state.requestsWindow.selectedRequests = selected ?? []
      },
    ]

    static var previews: some View {
      ForEach(allPreviews) {
        RequestsTable(requests: mockRequests)
          .store($0)
          .requestsPreview()
      }
    }
  }
#endif
