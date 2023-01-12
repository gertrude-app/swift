import SwiftUI

enum TestState: Equatable {
  case waiting
  case testing
  case error(String)
  case success(URL)
}

struct TestScreenshotView: View {
  @State private var resolution: String = "1200"
  @State private var testState: TestState = .waiting

  var body: some View {
    HStack {
      switch testState {
      case .waiting:
        Button("Test Screenshot @", action: takeScreenshot)
        TextField("", text: $resolution)
          .frame(width: 45)
          .padding(.leading, -5)
        Text("px").padding(.leading, -6)
      case .testing:
        ProgressView()
      case .error(let error):
        ErrorMessage(error)
      case .success(let url):
        Button(
          "Success! Click to view",
          action: {
            testState = .waiting
            NSWorkspace.shared.open(url)
          }
        )
      }
    }
  }

  private func takeScreenshot() {
    guard let userSize = Int(resolution) else {
      testState = .error("Invalid resolution")
      return
    }
    let size = max(500, userSize)
    testState = .testing
    Screenshot.shared.take(width: size) { result in
      guard let stringUrl = result, let url = URL(string: stringUrl) else {
        testState = .error("Network error")
        return
      }
      testState = .success(url)
    }
  }
}

struct TestScreenshotView_Previews: PreviewProvider {
  static var previews: some View {
    TestScreenshotView().adminPreview()
  }
}
