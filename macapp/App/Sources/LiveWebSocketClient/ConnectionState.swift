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
    log: @Sendable (String) -> Void = { _ in }
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
        return .connected
      case .initiatingDisconnect:
        return .disconnected
      default:
        return self
      }

    case .waitingForPong:
      switch event {
      case .receivedPong:
        return .connected
      case .failedToReceiveTimelyPong, .initiatingDisconnect:
        return .disconnected
      default:
        return self
      }

    case .disconnected:
      switch event {
      case .initiatingConnection:
        return .idle
      default:
        return self
      }

    case .connected:
      switch event {
      case .receivedDisconnected, .receivedCancelled, .initiatingDisconnect:
        return .disconnected
      case .sentPing:
        return .waitingForPong
      default:
        return self
      }

    case .connecting:
      switch event {

      case .receivedConnected:
        return .connected

      case .receivedCancelled:
        return .disconnected

      case .receivedDisconnected:
        return .disconnected

      case .sentPing,
           .failedToReceiveTimelyPong,
           .initiatingConnection,
           .initiatingDisconnect,
           .receivedPong:
        return self
      }
    }
  }
}
