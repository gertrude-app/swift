import Gertie
import MacAppRoute
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

final class RouterTests: XCTestCase {
  let router = MacAppRoute.router
  let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!

  func testPost() throws {
    var request = URLRequest(url: URL(string: "CreateSignedScreenshotUpload")!)
    request.setValue(self.token.uuidString, forHTTPHeaderField: "X-UserToken")

    let missingBody = try? self.router.match(request: request)
    expect(missingBody).toEqual(nil)

    let input = CreateSignedScreenshotUpload.Input(width: 100, height: 100)

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try self.router.match(request: request)
    let expected = MacAppRoute.userAuthed(self.token, .createSignedScreenshotUpload(input))
    expect(matched).toEqual(expected)
  }

  func testHeaderAuthed() throws {
    let input = FilterLogs(bundleIds: [:], events: [:])
    var request = URLRequest(url: URL(string: "LogFilterEvents")!)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)
    let route = MacAppRoute.userAuthed(self.token, .logFilterEvents(input))

    let missingHeader = try? self.router.match(request: request)
    expect(missingHeader).toEqual(nil)

    request.addValue(self.token.uuidString, forHTTPHeaderField: "X-UserToken")
    let matched = try self.router.match(request: request)
    expect(matched).toEqual(route)
  }
}
