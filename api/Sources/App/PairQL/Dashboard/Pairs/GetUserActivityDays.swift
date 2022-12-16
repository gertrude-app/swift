import Foundation
import TypescriptPairQL

struct DateRange: TypescriptNestable {
  let start: String
  let end: String
}

struct GetUserActivityDays: Pair, TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    let userId: UUID
    let dateRanges: [DateRange]
  }

  struct Output: TypescriptPairOutput {
    let userName: String
    let days: [Day]
  }

  struct Day: TypescriptNestable {
    let date: Date
    let numApproved: Int
    let totalItems: Int
  }
}
