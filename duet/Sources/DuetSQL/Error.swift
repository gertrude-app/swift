import Foundation

public enum DuetSQLError: Error, Equatable, LocalizedError {
  case notFound(String)
  case decodingFailed
  case nonUniformBulkInsertInput
  case emptyBulkInsertInput
  case tooManyResultsForDeleteOne
  case invalidEntity
  case missingExpectedColumn(String)
  case notImplemented(String)

  public var errorMessage: String {
    switch self {
    case .notFound:
      return "Database error: Not found"
    case .decodingFailed:
      return "Database error: Decoding failed"
    case .nonUniformBulkInsertInput:
      return "Database error: Non-uniform bulk insert input"
    case .emptyBulkInsertInput:
      return "Database error: Empty bulk insert input"
    case .tooManyResultsForDeleteOne:
      return "Database error: Too many results for delete one"
    case .invalidEntity:
      return "Database error: Attempt to create or update entity in invalid state"
    case .missingExpectedColumn(let name):
      return "Error: missing expected column `\(name)`"
    case .notImplemented(let message):
      return "Error: \(message)"
    }
  }

  public var errorDescription: String? {
    self.errorMessage
  }
}
