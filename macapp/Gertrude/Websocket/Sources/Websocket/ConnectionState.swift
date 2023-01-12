public struct ConnectionState {
  private var state = State.waitingForConnection
  public var get: State { state }

  public enum Event {
    case sentPing
    case failedToReceiveTimelyPong
    case initiatingConnection
    case initiatingDisconnect
    case receivedPong
    case receivedConnected
    case receivedCancelled
    case receivedDisconnected(code: UInt16)
  }

  public enum State: Equatable {
    case waitingForConnection
    case connected
    case disconnected
    case waitingForPong
  }

  public mutating func handle(_ event: Event) {
    switch state {

    case .waitingForConnection:
      switch event {
      case .receivedConnected:
        state = .connected
      default:
        break
      }

    case .waitingForPong:
      switch event {
      case .receivedPong:
        state = .connected
      case .failedToReceiveTimelyPong:
        state = .disconnected
      default:
        break
      }

    case .disconnected:
      switch event {
      case .initiatingConnection:
        state = .waitingForConnection
      default:
        break
      }

    case .connected:
      switch event {
      case .receivedDisconnected, .receivedCancelled, .initiatingDisconnect:
        state = .disconnected
      case .sentPing:
        state = .waitingForPong
      default:
        break
      }
    }
  }
}
