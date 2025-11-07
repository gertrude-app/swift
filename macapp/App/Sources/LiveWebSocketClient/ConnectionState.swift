import Foundation

public enum ConnectionState: Sendable {
  public enum Event: Sendable {
    case sentPing
    case failedToReceiveTimelyPong
    case initiatingConnection
    case initiatingDisconnect
    case receivedPong
    case receivedConnected
    case receivedCancelled
    case receivedDisconnected(code: UInt16)
  }

  case idle
  case connected
  case connecting
  case disconnected
  case waitingForPong

  public func receive(
    _ event: Event,
    log: @Sendable (String) -> Void = { _ in },
  ) -> ConnectionState {
    let prev = self
    let next = self.transition(event)
    log("- transition: \(prev) + \(event) -> \(next)")
    return next
  }

  public func transition(_ event: Event) -> ConnectionState {
    switch self {

    case .idle:
      switch event {
      case .receivedConnected:
        .connected
      case .initiatingDisconnect:
        .disconnected
      default:
        self
      }

    case .waitingForPong:
      switch event {
      case .receivedPong:
        .connected
      case .failedToReceiveTimelyPong, .initiatingDisconnect:
        .disconnected
      default:
        self
      }

    case .disconnected:
      switch event {
      case .initiatingConnection:
        .idle
      default:
        self
      }

    case .connected:
      switch event {
      case .receivedDisconnected, .receivedCancelled, .initiatingDisconnect:
        .disconnected
      case .sentPing:
        .waitingForPong
      default:
        self
      }

    case .connecting:
      switch event {

      case .receivedConnected:
        .connected

      case .receivedCancelled:
        .disconnected

      case .receivedDisconnected:
        .disconnected

      case .sentPing,
           .failedToReceiveTimelyPong,
           .initiatingConnection,
           .initiatingDisconnect,
           .receivedPong:
        self
      }
    }
  }
}
