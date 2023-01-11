import TaggedTime

public enum WebsocketMsg {
  public enum Error {
    public static let USER_TOKEN_NOT_FOUND: UInt16 = 4999
  }

  public enum AppToApi {
    public enum MessageType: String, Codable, Equatable {
      case currentFilterState
    }

    public struct Message: Codable, Equatable {
      public var type: MessageType

      public init(type: MessageType) {
        self.type = type
      }

      public struct CurrentFilterState: Codable, Equatable {
        public private(set) var type = MessageType.currentFilterState
        public var state: FilterState

        public init(_ state: FilterState) {
          self.state = state
        }
      }
    }
  }

  public enum ApiToApp {
    public enum MessageType: String, Codable, Equatable {
      case userUpdated
      case unlockRequestUpdated
      case requestFilterState
      case suspendFilterRequestDenied
      case suspendFilter
    }

    public struct Message: Codable, Equatable {
      public var type: MessageType

      public init(type: MessageType) {
        self.type = type
      }

      public struct RequestCurrentFilterState: Codable, Equatable {
        public private(set) var type = MessageType.requestFilterState
        public init() {}
      }

      public struct SuspendFilter: Codable, Equatable {
        public private(set) var type = MessageType.suspendFilter
        public var suspension: FilterSuspension
        public var comment: String?

        public init(suspension: FilterSuspension, comment: String? = nil) {
          self.suspension = suspension
          self.comment = comment
        }
      }

      public struct SuspendFilterRequestDenied: Codable, Equatable {
        public private(set) var type = MessageType.suspendFilterRequestDenied
        public var requestComment: String?
        public var responseComment: String?

        public init(requestComment: String?, responseComment: String?) {
          self.requestComment = requestComment
          self.responseComment = responseComment
        }
      }

      public struct UnlockRequestUpdated: Codable, Equatable {
        public private(set) var type = MessageType.unlockRequestUpdated
        public var status: RequestStatus
        public var target: String
        public var comment: String?
        public var responseComment: String?

        public init(
          status: RequestStatus,
          target: String,
          comment: String? = nil,
          responseComment: String? = nil
        ) {
          self.status = status
          self.target = target
          self.comment = comment
          self.responseComment = responseComment
        }
      }
    }
  }
}
