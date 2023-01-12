import SwiftUI

struct AdminWindow: View, StoreView {
  static let MIN_WIDTH: CGFloat = 815
  static let MIN_HEIGHT: CGFloat = 400

  @EnvironmentObject var store: AppStore

  var windowHeight: CGFloat {
    var height = Self.MIN_HEIGHT
    if store.state.accountStatus == .needsAttention {
      height += 40
    }
    return height
  }

  var body: some View {
    VStack {
      switch store.state.adminWindow {
      case .connect:
        ConnectScreen()
      default:
        MainAdminScreen()
      }
    }
    .infinite()
    .frame(minWidth: Self.MIN_WIDTH, minHeight: windowHeight)
  }
}

struct AdminWindow_Previews: PreviewProvider, GertrudeProvider {
  static var cases: [StateCustomizer] = [
    { state in state.adminWindow = .default },
    { state in state.adminWindow = .connect(AdminWindowState.ConnectState()) },
  ]

  static var previews: some View {
    ForEach(allPreviews) {
      AdminWindow().store($0).adminPreview()
    }
  }
}
