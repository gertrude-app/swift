import Foundation
import PairQL
import Gertie

public struct CreateNetworkDecisions: Pair {
  public static let auth: ClientAuth = .user

  public typealias Input = [DecisionInput]

  public struct DecisionInput: PairInput {
    public var id: UUID?
    public var verdict: NetworkDecisionVerdict
    public var reason: NetworkDecisionReason
    public var ipProtocolNumber: Int?
    public var responsibleKeyId: UUID?
    public var hostname: String?
    public var url: String?
    public var ipAddress: String?
    public var appBundleId: String?
    public var time: Date
    public var count: Int

    public init(
      id: UUID? = nil,
      verdict: NetworkDecisionVerdict,
      reason: NetworkDecisionReason,
      ipProtocolNumber: Int? = nil,
      responsibleKeyId: UUID? = nil,
      hostname: String? = nil,
      url: String? = nil,
      ipAddress: String? = nil,
      appBundleId: String? = nil,
      time: Date,
      count: Int
    ) {
      self.id = id
      self.verdict = verdict
      self.reason = reason
      self.ipProtocolNumber = ipProtocolNumber
      self.responsibleKeyId = responsibleKeyId
      self.hostname = hostname
      self.url = url
      self.ipAddress = ipAddress
      self.appBundleId = appBundleId
      self.time = time
      self.count = count
    }
  }
}
