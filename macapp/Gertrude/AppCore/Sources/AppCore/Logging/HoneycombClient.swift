import Combine
import Foundation
import Shared
import SharedCore
import XCore

extension Honeycomb {
  struct Client {
    var addDefaultMeta: (Log.Meta) -> Void
    var send: ([Event]) -> AnyPublisher<Bool, Never>
  }
}

extension Honeycomb.Client {
  static func live(defaultMeta: Log.Meta = [:]) -> Self {
    let os = OsClient.live
    let version = os.version()
    var meta = defaultMeta.merging([
      "os.version": .string(version.string),
      "os.version_name": .string(version.name),
      "os.major_version": .int(version.majorVersion),
      "os.minor_version": .int(version.minorVersion),
      "os.patch_version": .int(version.patchVersion),
      "device.arch": .init(os.arch()?.rawValue),
      "device.model": .init(os.modelIdentifier()),
      "device.serial_number": .init(os.serialNumber()),
    ]) { _, new in new }

    return Honeycomb.Client(
      addDefaultMeta: { meta.merge($0) { _, new in new } },
      send: { _send(events: $0, defaultMeta: meta) }
    )
  }

  static let live = Honeycomb.Client.live()
}

extension Honeycomb.Client {
  static let noop = Honeycomb.Client(
    addDefaultMeta: { _ in },
    send: { _ in .true }
  )
}

// implementation

private func _send(
  events: [Honeycomb.Event],
  defaultMeta: Log.Meta = [:]
) -> AnyPublisher<Bool, Never> {
  let events = events.map { event -> Honeycomb.Event in
    var event = event
    event.data = event.data.merging(defaultMeta) { _, new in new }
    return event
  }

  guard let jsonData = try? JSON.data(events) else {
    return .false
  }

  guard jsonData.count < HONEYCOMB_BATCH_SIZE_LIMIT else {
    var merged: AnyPublisher<Bool, Never> = .true
    for chunk in events.chunked(into: events.count / 2 + 1) {
      merged = merged
        .merge(with: _send(events: chunk, defaultMeta: defaultMeta))
        .eraseToAnyPublisher()
    }
    return merged
  }

  let endpoint = "https://api.honeycomb.io/1/batch/macosapp"
  guard let url = URL(string: endpoint) else {
    return .true
  }

  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue(
    isDev() ? ApiKeys.HONEYCOMB_DEV : ApiKeys.HONEYCOMB_PROD,
    forHTTPHeaderField: "X-Honeycomb-Team"
  )
  request.httpBody = jsonData

  return URLSession.shared.dataTaskPublisher(for: request)
    .map(\.data)
    .tryMap { data in
      if let error = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        // @TODO: bugsnag?
        #if DEBUG
          print("\n\n!!! HONEYCOMB SEND ERROR: \(error.error)\n\n")
        #endif
        throw Unit.value
      }
      return data
    }
    .decode(type: [EventResponse].self, decoder: JSONDecoder())
    .map { $0.allSatisfy { $0.status == 202 } }
    .catch { _ in Just(false) }
    .eraseToAnyPublisher()
}

private struct EventResponse: Decodable {
  var status: Int
}

private struct ErrorResponse: Decodable {
  var error: String
}

private let HONEYCOMB_BATCH_SIZE_LIMIT = 5 * 1024 * 1024 // 5mb

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
