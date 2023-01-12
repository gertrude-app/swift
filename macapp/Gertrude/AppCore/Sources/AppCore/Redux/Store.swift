import Combine
import Foundation
import SwiftUI

typealias Reducer<State, Action, Environment> =
  (inout State, Action, Environment) -> AnyPublisher<Action, Never>?

final class Store<State, Action, Environment>: ObservableObject {
  @Published private(set) var state: State

  var environment: Environment
  private let reducer: Reducer<State, Action, Environment>
  private var effectCancellables: Set<AnyCancellable> = []

  init(
    initialState: State,
    reducer: @escaping Reducer<State, Action, Environment>,
    environment: Environment
  ) {
    state = initialState
    self.reducer = reducer
    self.environment = environment
  }

  func send(_ action: Action) {
    guard let effect = reducer(&state, action, environment) else {
      return
    }

    effect
      .receive(on: DispatchQueue.main)
      .sink(receiveValue: send)
      .store(in: &effectCancellables)
  }

  func action(_ action: Action) -> () -> Void {
    { self.send(action) }
  }

  func bind<T>(_ path: KeyPath<State, T>, _ action: Action) -> Binding<T> {
    Binding(
      get: { self.state[keyPath: path] },
      set: { [weak self] _ in self?.send(action) }
    )
  }

  func bind<T>(_ path: KeyPath<State, T>, _ action: @escaping (T) -> Action) -> Binding<T> {
    Binding(
      get: { self.state[keyPath: path] },
      set: { [weak self] in self?.send(action($0)) }
    )
  }

  func bind<T>(_ get: @escaping () -> T, _ action: @escaping (T) -> Action) -> Binding<T> {
    Binding(
      get: get,
      set: { [weak self] in self?.send(action($0)) }
    )
  }
}

extension Store where State == AppState {
  func ifFilterConnected(_ work: () -> Void) {
    if state.filterStatus == .installedAndRunning {
      work()
    }
  }
}
