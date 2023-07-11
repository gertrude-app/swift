import Combine
import Foundation

public protocol SyncDeps: Sendable {
  static var live: Self { get }
}

public protocol SyncTestDeps: Sendable {
  static var failing: Self { get }
}

public protocol SyncReducer<State, Action, Deps> {
  associatedtype State: Equatable, Sendable
  associatedtype Action: Equatable, Sendable
  associatedtype Deps: SyncDeps
  func reduce(into state: inout State, action: Action, deps: Deps) -> Effect<Action>
}

public final class Store<R: SyncReducer> {
  private let reducer: R
  private var deps: R.Deps
  private var effectCancellables: [UUID: AnyCancellable] = [:]

  fileprivate var _state: CurrentValueSubject<R.State, Never>

  public var state: R.State {
    _state.value
  }

  public var publisher: StorePublisher<R.State> {
    StorePublisher(store: self)
  }

  public init(initialState: R.State, reducer: R, deps: R.Deps) {
    self.reducer = reducer
    _state = CurrentValueSubject(initialState)
    self.deps = deps
  }

  public func send(_ action: R.Action) {
    let effect = reducer.reduce(into: &_state.value, action: action, deps: deps)

    switch effect.operation {
    case .none:
      break

    case .run(let operation):
      operation(Send { self.send($0) })

    case .publisher(let publisher):
      let uuid = UUID()
      let effectCancellable = publisher
        .handleEvents(
          receiveCancel: { [weak self] in
            self?.effectCancellables[uuid] = nil
          }
        )
        .sink(
          receiveCompletion: { [weak self] _ in
            self?.effectCancellables[uuid] = nil
          },
          receiveValue: { [weak self] effectAction in
            guard let self else { return }
            self.send(effectAction)
          }
        )
      effectCancellables[uuid] = effectCancellable
    }
  }
}

@dynamicMemberLookup
public struct StorePublisher<State>: Publisher {
  public typealias Output = State
  public typealias Failure = Never

  public let upstream: AnyPublisher<State, Never>
  public let store: Any

  fileprivate init<R: SyncReducer>(store: Store<R>) where R.State == State {
    self.store = store
    self.upstream = store._state.eraseToAnyPublisher()
  }

  public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
    self.upstream.subscribe(
      AnySubscriber(
        receiveSubscription: subscriber.receive(subscription:),
        receiveValue: subscriber.receive(_:),
        receiveCompletion: { [store = self.store] in
          subscriber.receive(completion: $0)
          _ = store
        }
      )
    )
  }

  private init<P: Publisher>(
    upstream: P,
    store: Any
  ) where P.Output == Output, P.Failure == Failure {
    self.upstream = upstream.eraseToAnyPublisher()
    self.store = store
  }

  public subscript<Value: Equatable>(
    dynamicMember keyPath: KeyPath<State, Value>
  ) -> StorePublisher<Value> {
    .init(upstream: self.upstream.map(keyPath).removeDuplicates(), store: self.store)
  }
}
