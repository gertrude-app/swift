import Combine
import Network

struct ConnectionClient {
  var isConnected: () -> Bool
  var publisher: AnyPublisher<Bool, Never>
}

extension ConnectionClient {
  static func live(queue: DispatchQueue = .main) -> Self {
    let monitor = NWPathMonitor()
    let subject = CurrentValueSubject<Bool, Never>(true)
    monitor.pathUpdateHandler = { subject.send($0.status == .satisfied) }
    monitor.start(queue: queue)

    return ConnectionClient(
      isConnected: { subject.value },
      publisher: subject
        .handleEvents()
        .removeDuplicates()
        .eraseToAnyPublisher()
    )
  }

  static let live = ConnectionClient.live(queue: .main)
}

extension ConnectionClient {
  static let connected = ConnectionClient(
    isConnected: { true },
    publisher: CurrentValueSubject<Bool, Never>(true).eraseToAnyPublisher()
  )

  static let notConnected = ConnectionClient(
    isConnected: { false },
    publisher: CurrentValueSubject<Bool, Never>(false).eraseToAnyPublisher()
  )
}
