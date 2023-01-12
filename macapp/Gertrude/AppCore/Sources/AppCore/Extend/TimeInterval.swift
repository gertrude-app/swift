import Foundation

extension TimeInterval {
  static func hours(_ hours: Int) -> Self {
    Self(hours * 60 * 60)
  }

  static func minutes(_ minutes: Int) -> Self {
    Self(minutes * 60)
  }

  static func seconds(_ seconds: Int) -> Self {
    Self(seconds)
  }
}
