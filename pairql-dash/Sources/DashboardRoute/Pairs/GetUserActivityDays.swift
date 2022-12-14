import Foundation
import TypescriptPairQL

public struct DateRange: TypescriptNestable {
  public let start: String
  public let end: String

  public init(start: String, end: String) {
    self.start = start
    self.end = end
  }
}

public struct GetUserActivityDays: Pair, TypescriptPair {
  public static var auth: ClientAuth = .admin

  public struct Input: TypescriptPairInput {
    public let userId: UUID
    public let dateRanges: [DateRange]

    public init(userId: UUID, dateRanges: [DateRange]) {
      self.userId = userId
      self.dateRanges = dateRanges
    }
  }

  public struct Output: TypescriptPairOutput {
    public let userName: String
    public let days: [Day]

    public init(userName: String, days: [Day]) {
      self.userName = userName
      self.days = days
    }
  }

  public struct Day: TypescriptNestable {
    public let date: Date
    public let numApproved: Int
    public let totalItems: Int

    public init(date: Date, numApproved: Int, totalItems: Int) {
      self.date = date
      self.numApproved = numApproved
      self.totalItems = totalItems
    }
  }
}
