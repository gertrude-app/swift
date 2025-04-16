import ComposableArchitecture
import LibApp
import SwiftUI

struct RequestSuspensionView: View {
  @Bindable var store: StoreOf<RequestSuspension>
  @State private var _comment: String = ""

  var comment: String? {
    guard !self._comment.isEmpty else { return nil }
    return self._comment
  }

  var body: some View {
    switch self.store.state {
    case .customizing:
      VStack {
        TextField("Comment", text: self.$_comment)
          .padding(20)
          .border(Color.gray)
        BigButton("5 minutes", type: .button {
          self.store.send(.submitRequest(duration: 60 * 5, comment: self.comment))
        })
        BigButton("15 minutes", type: .button {
          self.store.send(.submitRequest(duration: 60 * 15, comment: self.comment))
        })
      }
      .padding(20)
    case .requesting:
      ProgressView()
    case .requestFailed(error: let error):
      Text("Request failed: \(error)")
    case .waitingForDecision:
      Text("Waiting for decision")
    case .denied(let comment):
      if let comment {
        Text("Suspension denied: \(comment)")
      } else {
        Text("Suspension denied")
      }
    case .granted(let duration, let comment):
      VStack {
        if let comment {
          Text("Suspension granted for \(duration) seconds: \(comment)")
        } else {
          Text("Suspension granted for \(duration) seconds")
        }
        BigButton("Start suspension", type: .button {
          self.store.send(.startSuspensionTapped(duration))
        })
      }
    case .suspended:
      Text("Filter is suspended")
    }
  }
}
