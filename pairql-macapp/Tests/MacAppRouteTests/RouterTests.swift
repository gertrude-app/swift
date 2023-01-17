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
    request.setValue(token.uuidString, forHTTPHeaderField: "X-UserToken")

    let missingBody = try? router.match(request: request)
    expect(missingBody).toEqual(nil)

    let input = CreateSignedScreenshotUpload.Input(width: 100, height: 100)

    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try router.match(request: request)
    let expected = MacAppRoute.userAuthed(token, .createSignedScreenshotUpload(input))
    expect(matched).toEqual(expected)
  }

  func testHeaderAuthed() throws {
    var request = URLRequest(url: URL(string: "GetAccountStatus")!)
    let route = MacAppRoute.userAuthed(token, .getAccountStatus)

    let missingHeader = try? router.match(request: request)
    expect(missingHeader).toEqual(nil)

    request.addValue(token.uuidString, forHTTPHeaderField: "X-UserToken")
    let matched = try router.match(request: request)
    expect(matched).toEqual(route)
  }
}
