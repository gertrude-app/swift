import Dependencies
import Foundation

public protocol EndpointOverridable {
  static var endpointDefault: URL { get }
  static var endpointOverride: LockIsolated<URL?> { get }
}

public extension EndpointOverridable {
  static var endpoint: URL {
    endpointOverride.value ?? endpointDefault
  }

  var endpoint: URL {
    Self.endpoint
  }

  func defaultEndpoint() -> URL {
    Self.endpointDefault
  }

  static func defaultEndpoint() -> URL {
    Self.endpointDefault
  }

  func clearEndpointOverride() {
    Self.endpointOverride.setValue(nil)
  }

  func endpointOverride() -> URL? {
    Self.endpointOverride.value
  }

  static func endpointOverride() -> URL? {
    Self.endpointOverride.value
  }

  func setEndpointOverride(_ url: URL) {
    Self.endpointOverride.setValue(url)
  }

  func updateEndpointOverride(_ input: String?) async {
    if let input, let url = URL(string: input), !input.isEmpty {
      setEndpointOverride(url)
    } else {
      clearEndpointOverride()
    }
  }
}
