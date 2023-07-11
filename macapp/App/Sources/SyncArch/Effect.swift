import Combine
import Foundation
import os.log

public struct Effect<Action> {
  enum Operation {
    case none
    case publisher(AnyPublisher<Action, Never>)
    case run(@Sendable (Send<Action>) -> Void)
  }

  let operation: Operation

  init(operation: Operation) {
    self.operation = operation
  }
}

public extension Effect {
  static var none: Self {
    Self(operation: .none)
  }

  static func publisher<P: Publisher>(_ createPublisher: @escaping () -> P) -> Self
    where P.Output == Action, P.Failure == Never {
    Self(operation: .publisher(Deferred(createPublisher: createPublisher).eraseToAnyPublisher()))
  }

  static func run(
    operation: @escaping @Sendable (Send<Action>) throws -> Void,
    catch handler: (@Sendable (Error, Send<Action>) -> Void)? = nil,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> Self {
    Self(
      operation: .run { send in
        do {
          try operation(send)
        } catch {
          guard let handler else {
            #if DEBUG
              Swift.print("⛔️ Effect.run returned from \(fileID):\(line) threw an unhandled error.")
              os_log("[G•] ⛔️ Effect.run unhandled err %{public}s:%{public}d", "\(fileID)", line)
            #endif
            return
          }
          handler(error, send)
        }
      }
    )
  }

  static func merge(_ effects: Self...) -> Self {
    Self.merge(effects)
  }

  static func merge<S: Sequence>(_ effects: S) -> Self where S.Element == Self {
    effects.reduce(.none) { $0.merge(with: $1) }
  }

  func merge(with other: Self) -> Self {
    switch (operation, other.operation) {
    case (_, .none):
      return self
    case (.none, _):
      return other
    case (.publisher, .publisher), (.run, .publisher), (.publisher, .run):
      return Self(operation: .publisher(Publishers.Merge(self, other).eraseToAnyPublisher()))
    case (.run(let lhsOperation), .run(let rhsOperation)):
      return Self(
        operation: .run { send in
          lhsOperation(send)
          rhsOperation(send)
        }
      )
    }
  }
}

public struct Send<Action> {
  public let send: (Action) -> Void

  public init(send: @escaping (Action) -> Void) {
    self.send = send
  }

  public func callAsFunction(_ action: Action) {
    send(action)
  }
}

extension Effect: Publisher {
  public typealias Output = Action
  public typealias Failure = Never

  public func receive<S: Combine.Subscriber>(
    subscriber: S
  ) where S.Input == Action, S.Failure == Never {
    publisher.subscribe(subscriber)
  }

  var publisher: AnyPublisher<Action, Never> {
    switch operation {
    case .none:
      return Empty().eraseToAnyPublisher()
    case .publisher(let publisher):
      return publisher
    case .run(let operation):
      let subject = PassthroughSubject<Action, Never>()
      operation(.init { subject.send($0) })
      return subject.eraseToAnyPublisher()

      // return .create { subscriber in
      //   defer { subscriber.send(completion: .finished) }
      //   let send = Send<Action> { subscriber.send($0) }
      //   operation(send)
      //   // subscriber
      //   fatalError("not implemented")
      // let task = Task(priority: priority) { @MainActor in
      //   defer { subscriber.send(completion: .finished) }
      //   #if DEBUG
      //     var isCompleted = false
      //     defer { isCompleted = true }
      //   #endif
      //   let send = Send<Action> {
      //     #if DEBUG
      //       if isCompleted {
      //         runtimeWarn(
      //           """
      //           An action was sent from a completed effect:

      //             Action:
      //               \(debugCaseOutput($0))

      //           Avoid sending actions using the 'send' argument from 'EffectTask.run' after \
      //           the effect has completed. This can happen if you escape the 'send' argument in \
      //           an unstructured context.

      //           To fix this, make sure that your 'run' closure does not return until you're \
      //           done calling 'send'.
      //           """
      //         )
      //       }
      //     #endif
      //     subscriber.send($0)
      //   }
      // await operation(send)
      // }
      // return AnyCancellable {
      //   task.cancel()
      // }
      // }
    }
  }
}

// extension AnyPublisher where Failure == Never {
//   private init(
//     _ callback: @escaping (Effect<Output>.Subscriber) -> Void
//   ) {
//     self = Publishers.Create(callback: callback).eraseToAnyPublisher()
//   }

//   static func create(
//     _ factory: @escaping (Effect<Output>.Subscriber) -> Void
//   ) -> AnyPublisher<Output, Never> {
//     AnyPublisher(factory)
//   }
// }

// public extension Effect {
//   struct Subscriber {
//     private let _send: (Action) -> Void
//     private let _complete: (Subscribers.Completion<Failure>) -> Void

//     init(
//       send: @escaping (Action) -> Void,
//       complete: @escaping (Subscribers.Completion<Failure>) -> Void
//     ) {
//       _send = send
//       _complete = complete
//     }

//     public func send(_ value: Action) {
//       _send(value)
//     }

//     public func send(completion: Subscribers.Completion<Failure>) {
//       _complete(completion)
//     }
//   }
// }

// private extension Publishers {
//   class Create<Output>: Publisher {
//     typealias Failure = Never
//     private let callback: (Effect<Output>.Subscriber) -> Void

//     init(callback: @escaping (Effect<Output>.Subscriber) -> Void) {
//       self.callback = callback
//     }

//     func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Never {
//       subscriber.receive(subscription: Subscription(callback: callback, downstream: subscriber))
//     }
//   }
// }

// private extension Publishers.Create {
//   final class Subscription<Downstream: Subscriber>: Combine.Subscription
//     where Downstream.Input == Output, Downstream.Failure == Never {
//     private let buffer: DemandBuffer<Downstream>
//     private var cancellable: Cancellable?

//     init(
//       callback: @escaping (Effect<Output>.Subscriber) -> Cancellable,
//       downstream: Downstream
//     ) {
//       buffer = DemandBuffer(subscriber: downstream)

//       let cancellable = callback(
//         .init(
//           send: { [weak self] in _ = self?.buffer.buffer(value: $0) },
//           complete: { [weak self] in self?.buffer.complete(completion: $0) }
//         )
//       )

//       self.cancellable = cancellable
//     }

//     func request(_ demand: Subscribers.Demand) {
//       _ = buffer.demand(demand)
//     }

//     func cancel() {
//       cancellable?.cancel()
//     }
//   }
// }

// extension Publishers.Create.Subscription: CustomStringConvertible {
//   var description: String {
//     "Create.Subscription<\(Output.self)>"
//   }
// }

// final class DemandBuffer<S: Subscriber>: @unchecked Sendable {
//   private var buffer = [S.Input]()
//   private let subscriber: S
//   private var completion: Subscribers.Completion<S.Failure>?
//   private var demandState = Demand()
//   private let lock: os_unfair_lock_t

//   init(subscriber: S) {
//     self.subscriber = subscriber
//     lock = os_unfair_lock_t.allocate(capacity: 1)
//     lock.initialize(to: os_unfair_lock())
//   }

//   deinit {
//     self.lock.deinitialize(count: 1)
//     self.lock.deallocate()
//   }

//   func buffer(value: S.Input) -> Subscribers.Demand {
//     precondition(
//       completion == nil, "How could a completed publisher sent values?! Beats me 🤷‍♂️"
//     )

//     switch demandState.requested {
//     case .unlimited:
//       return subscriber.receive(value)
//     default:
//       buffer.append(value)
//       return flush()
//     }
//   }

//   func complete(completion: Subscribers.Completion<S.Failure>) {
//     precondition(
//       self.completion == nil, "Completion have already occurred, which is quite awkward 🥺"
//     )

//     self.completion = completion
//     _ = flush()
//   }

//   func demand(_ demand: Subscribers.Demand) -> Subscribers.Demand {
//     flush(adding: demand)
//   }

//   private func flush(adding newDemand: Subscribers.Demand? = nil) -> Subscribers.Demand {
//     lock.sync {

//       if let newDemand = newDemand {
//         demandState.requested += newDemand
//       }

//       // If buffer isn't ready for flushing, return immediately
//       guard demandState.requested > 0 || newDemand == Subscribers.Demand.none else { return .none }

//       while !buffer.isEmpty, demandState.processed < demandState.requested {
//         demandState.requested += subscriber.receive(buffer.remove(at: 0))
//         demandState.processed += 1
//       }

//       if let completion = completion {
//         // Completion event was already sent
//         buffer = []
//         demandState = .init()
//         self.completion = nil
//         subscriber.receive(completion: completion)
//         return .none
//       }

//       let sentDemand = demandState.requested - demandState.sent
//       demandState.sent += sentDemand
//       return sentDemand
//     }
//   }

//   struct Demand {
//     var processed: Subscribers.Demand = .none
//     var requested: Subscribers.Demand = .none
//     var sent: Subscribers.Demand = .none
//   }
// }

// extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
//   @discardableResult
//   func sync<R>(_ work: () -> R) -> R {
//     os_unfair_lock_lock(self)
//     defer { os_unfair_lock_unlock(self) }
//     return work()
//   }
// }

// public extension NSRecursiveLock {
//   @discardableResult
//   func sync<R>(work: () -> R) -> R {
//     lock()
//     defer { self.unlock() }
//     return work()
//   }
// }
