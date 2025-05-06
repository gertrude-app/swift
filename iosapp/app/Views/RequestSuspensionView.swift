import ComposableArchitecture
import LibApp
import ReplayKit
import SwiftUI

struct RequestSuspensionView: View {
  @Bindable var store: StoreOf<RequestSuspension>
  @State private var _comment: String = ""

  private let broadcastPicker = RPSystemBroadcastPickerView()

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
          // TODO: need to hook into start of broadcast, not tap
          self.store.send(.startSuspensionTapped(duration))
          self.broadcastPicker.preferredExtension = "com.netrivet.gertrude-ios.app.recorder"
          self.broadcastPicker.showsMicrophoneButton = false
          // This workaround displays the prompt while minimizing encumbrance with UIKit.
          for subview in self.broadcastPicker.subviews where subview is UIButton {
            (subview as? UIButton)?.sendActions(for: .touchUpInside)
          }
        })
      }
    case .suspended:
      Text("Filter is suspended")
    }
  }
}
