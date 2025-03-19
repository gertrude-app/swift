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
      "Database error: Not found"
    case .decodingFailed:
      "Database error: Decoding failed"
    case .nonUniformBulkInsertInput:
      "Database error: Non-uniform bulk insert input"
    case .emptyBulkInsertInput:
      "Database error: Empty bulk insert input"
    case .tooManyResultsForDeleteOne:
      "Database error: Too many results for delete one"
    case .invalidEntity:
      "Database error: Attempt to create or update entity in invalid state"
    case .missingExpectedColumn(let name):
      "Error: missing expected column `\(name)`"
    case .notImplemented(let message):
      "Error: \(message)"
    }
  }

  public var errorDescription: String? {
    self.errorMessage
  }
}
