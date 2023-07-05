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

    os_log("[G•] system extension request finished successfully")
    Task { @MainActor in
      await activationRequest.setValue(.delegateRequestSucceeded)
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    unexpectedError(id: "7bc4b55a")
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
    os_log("[G•] system extension request replacing %{public}@ with %{public}@", old, new)
    return .replace
  }
}
