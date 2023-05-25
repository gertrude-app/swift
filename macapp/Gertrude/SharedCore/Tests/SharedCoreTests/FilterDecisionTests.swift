import Gertie
import SharedCore
import XCTest

class FilterDecisionTests: XCTestCase {
  func testReportsAppBundleIdOverFlowBundleIdIfDifferent() {
    let app = AppDescriptor(bundleId: "com.chrome", slug: "chrome")
    let decision = FilterDecision(
      verdict: .block,
      reason: .defaultNotAllowed,
      app: app,
      filterFlow: .init(bundleId: "WXCTWO3432.com.chrome" /* <-- different from app.bundleId */ )
    )
    XCTAssertEqual(decision.bundleId, app.bundleId)
  }
}
