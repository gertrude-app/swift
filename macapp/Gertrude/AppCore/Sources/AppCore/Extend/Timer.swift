import Foundation

extension Timer {
  static func repeating(
    every interval: TimeInterval,
    block: @escaping (Timer) -> Void
  ) -> Timer {
    Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: block)
  }

  static func repeating(
    every interval: Int,
    block: @escaping (Timer) -> Void
  ) -> Timer {
    Timer.scheduledTimer(withTimeInterval: Double(interval), repeats: true, block: block)
  }
}
