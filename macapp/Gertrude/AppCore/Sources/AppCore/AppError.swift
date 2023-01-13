import SharedCore

public enum AppError {
  case refreshRulesFailed(ApiClient.Error)
  case filterSuspensionRequestFailed(ApiClient.Error)
  case unlockRequestFailed(ApiClient.Error)

  var error: ApiClient.Error {
    switch self {
    case .refreshRulesFailed(let error):
      return error
    case .filterSuspensionRequestFailed(let error):
      return error
    case .unlockRequestFailed(let error):
      return error
    }
  }
}

func errorMsg(_ event: AppError) -> String {
  var error: String?
  if event.error.tag == .userTokenNotFound {
    return ACCOUNT_CONNECTION_LOST
  } else {
    error = event.error.localizedDescription
  }

  if let error = error?.lowercased() {
    // TODO: remove tight coupling on error message string somehow...
    if error.contains("auth token not found") {
      return ACCOUNT_CONNECTION_LOST
    }

    if error.contains("connection appears to be offline") {
      return e("""
      You appear to be offline. Check your internet connection and try again.
      """)
    }

    if error.contains("could not connect to the server") {
      return e("""
      It looks like the Gertrude API is having problems. Try again \
      in a few minutes, or contact support for more help.
      """)
    }
  }

  log(.unexplainedAppError(event))
  if isDev() {
    log(.level(.debug, "unexplained error raw string:", .primary(error)))
  }

  return e("""
  Sorry, an unexpected error occured. It may work if you try again \
  in a few minutes. Contact Gertrude support for more help.
  """)
}

private func e(_ string: String) -> String {
  assert(string.count < 150, "Error string too long: \(string)")
  return string
}

private var ACCOUNT_CONNECTION_LOST = e("""
Account connection lost. Have your parent reconnect \
the user in the \"Administrate > Actions\" screen."
""")
