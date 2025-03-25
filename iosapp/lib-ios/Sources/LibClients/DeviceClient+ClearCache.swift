import Combine
import Foundation
import os.log
import XCore

// tested numerous variations of this, and struggled to get much
// better performance than this. tried playing with number of threads,
// size of file, frequency of reporting, even dropping down to C, etc.
// either i'm dumb and am missing something obvious, or i'm sort of
// fundamentally I/O bound in some way I can't get around
@Sendable func doClearCache(_ totalAvailableSpace: Int?)
  -> AnyPublisher<DeviceClient.ClearCacheUpdate, Never> {
  let state = _State(totalAvailableSpace)
  Task {
    do {
      try FileManager.default.createDirectory(
        at: .fillDir,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      os_log("[G•] Error creating cache fill dir %{public}s", "\(error)")
      state.reportEvent(.errorCouldNotCreateDir)
      state.reportEvent(.finished)
      return
    }

    let FOUR_GB = 1_000_000_000 * 4
    let totalTasks = (totalAvailableSpace ?? 0) > FOUR_GB ? 12 : 1
    let filesize = 1024 * 1024 * 10 // 10MB

    await withThrowingTaskGroup(of: Void.self) { group in
      for t in 1 ... totalTasks {
        group.addTask {
          // NB: reusing the string seems to improve performance
          var filename = URL.fillDir.path + "/\(t)-0000000000.txt"
          for i in 0 ..< 1_000_000 {
            filename.removeLast(14)
            filename.append(String(format: "%010d.txt", i))
            do {
              try Data(repeating: 0, count: filesize)
                .write(to: URL(fileURLWithPath: filename))
            } catch {
              os_log("[G•] caught expected full disk error %{public}s", "\(error)")
              state.reportEvent(.finished)
              // NB: rethrow to tear down the task group, stopping all other threads
              throw error
            }

            // NB: (t + i) is to stagger threads reporting, reduce contention,
            // doesn't matter that these reports are ever-so-slightly innaccurate
            if (t + i) % 4 == 0 {
              state.reportEvent(.bytesCleared(filesize * 4))
              await Task.yield()
              if Task.isCancelled { return }
            }

            // NB: system can terminate the app if we get multiple full errors
            // so when we approach the end, reduce down to a single thread
            if t > 1, i % 15 == 0, state.estimateRemaining() < FOUR_GB {
              os_log("[G•] cache clear thread %{public}d bailing", t)
              return
            }
          }
        }
      }
    }
  }
  return state.publisher()
}

// NB: re @unchecked Sendable:
//   - the two combine subjects have internal locking
//   - self.cancellables is only touched in the fileprivate init
private final class _State: @unchecked Sendable {
  private let totalAvailableSpace: Int?
  // NB: combine subjects are thread-safe, per an apple engineer on swift forums
  // they lock internally, so it's safe to hammer them with events from multiple threads
  private let subject = PassthroughSubject<Int, Never>()
  private let state = CurrentValueSubject<DeviceClient.ClearCacheUpdate, Never>(.bytesCleared(0))
  private var cancellables: Set<AnyCancellable> = []

  fileprivate init(_ totalAvailableSpace: Int?) {
    self.totalAvailableSpace = totalAvailableSpace
    self.subject
      .sink { [weak self] newData in
        guard let self else { return }
        switch self.state.value {
        case .bytesCleared(let bytes):
          self.state.send(.bytesCleared(bytes + newData))
        case .errorCouldNotCreateDir, .finished:
          break
        }
      }
      .store(in: &self.cancellables)
  }

  func reportEvent(_ event: DeviceClient.ClearCacheUpdate) {
    switch event {
    case .bytesCleared(let bytes):
      self.subject.send(bytes)
    case .errorCouldNotCreateDir:
      self.state.send(.errorCouldNotCreateDir)
      self.state.send(completion: .finished)
    case .finished:
      Task { try? FileManager.default.removeItem(at: .fillDir) }
      os_log("[G•] finished clearing cache, removing fill dir")
      self.state.send(.finished)
      self.state.send(completion: .finished)
    }
  }

  func estimateRemaining() -> Int {
    guard let available = self.totalAvailableSpace else { return 0 }
    switch self.state.value {
    case .bytesCleared(let bytes):
      return available - bytes
    case .errorCouldNotCreateDir, .finished:
      return 0
    }
  }

  func publisher() -> AnyPublisher<DeviceClient.ClearCacheUpdate, Never> {
    self.state.eraseToAnyPublisher()
  }
}

extension URL {
  static var fillDir: URL {
    FileManager.default
      .urls(for: .documentDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("gertrude-fill-dir")
  }
}
