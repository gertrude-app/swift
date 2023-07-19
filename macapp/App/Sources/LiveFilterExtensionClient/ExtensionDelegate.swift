import ClientInterfaces
import NetworkExtension
import os.log
import SystemExtensions

extension FilterManager: OSSystemExtensionRequestDelegate {
  func request(
    _ request: OSSystemExtensionRequest,
    didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    guard result == .completed else {
      Task { @MainActor in
        await activationRequest.setValue(.delegateRequestFailed(nil))
        unexpectedError(id: "d86437ed")
      }
      return
    }

    os_log("[G•] APP system extension request finished successfully")
    Task { @MainActor in
      await activationRequest.setValue(.delegateRequestSucceeded)
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    // i'm pretty sure we only get in here when the user needs
    // to accept the security & permissions prompt in system settings
    // not an error state, so no need to log anything, but might be
    // a hook for some future feature or help screen for that step
  }

  func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
    Task { @MainActor in
      await activationRequest.setValue(.delegateRequestFailed(error))
      unexpectedError(id: "2362df24", error)
    }
  }

  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension extension: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction {
    let old = existing.bundleShortVersion
    let new = `extension`.bundleShortVersion
    os_log("[G•] APP system extension request replacing %{public}@ with %{public}@", old, new)
    return .replace
  }
}
