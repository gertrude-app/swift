import Foundation
import Gertie

@testable import Api

extension Release: RandomMocked {
  public static var mock: Release {
    Release(
      semver: "1.0.0",
      channel: .stable,
      signature: "VJwR3bN7V2AaN6FSy+M7LWWhb/wxHzAymCgtr+wJQ+3IZnYNoSFONXHeIkgkDlNcEYIgHQUZCrBqd8PL+YwzBA==",
      length: 555,
      revision: "73563e94567a902aa6709fe512e8f3f41d00a893",
      requirementPace: 10
    )
  }

  public static var empty: Release {
    Release(
      semver: "",
      channel: .stable,
      signature: "",
      length: 0,
      revision: "",
      requirementPace: nil
    )
  }

  public static var random: Release {
    Release(
      semver: "1.0.0".random,
      channel: {
        switch Int.random(in: 0 ... 2) {
        case 0: .stable
        case 1: .beta
        default: .canary
        }
      }(),
      signature: "signature".random,
      length: Int.random(in: 0 ... Int.max),
      revision: .init("revision".random),
      requirementPace: Bool.random() ? Int.random(in: 0 ... 100) : nil
    )
  }
}
