import Combine
import Foundation
import MacAppRoute
import Shared
import SharedCore
import XCore

extension ApiClient {
  static var live: Self {
    ApiClient(
      connectToUser: { verificationCode in
        guard let serialNumber = Device.shared.serialNumber else {
          return Fail(
            error: .precondition(ConnectApp.name, "Could not get device serial number")
              .logged
          )
          .eraseToAnyPublisher()
        }
        return Future {
          try await response(
            unauthed: .connectApp(.init(
              verificationCode: verificationCode,
              appVersion: Current.appVersion,
              hostname: Device.shared.hostname,
              modelIdentifier: Current.os.modelIdentifier() ?? "unknown",
              username: Device.shared.username,
              fullUsername: Device.shared.fullUsername,
              numericId: Int(exactly: Device.shared.numericUserId)!,
              serialNumber: serialNumber
            )),
            to: ConnectApp.self
          ).map { output in (
            userId: output.userId,
            userToken: output.token,
            userName: output.userName,
            deviceId: output.deviceId
          ) }.get()
        }.eraseToAnyPublisher()
      },

      createSuspendFilterRequest: { duration, comment in
        Future {
          try await response(
            .createSuspendFilterRequest(.init(duration: duration.rawValue, comment: comment)),
            to: CreateSuspendFilterRequest.self
          ).mapVoid().get()
        }.eraseToAnyPublisher()
      },

      createUnlockRequests: { ids, comment in
        Future {
          _ = try await response(
            .createUnlockRequests(ids.map { .init(networkDecisionId: $0, comment: comment) }),
            to: CreateUnlockRequests.self
          ).get()
        }.eraseToAnyPublisher()
      },

      getAccountStatus: {
        Future {
          try await response(.getAccountStatus, to: GetAccountStatus.self)
            .map(\.status).get()
        }.eraseToAnyPublisher()
      },

      refreshRules: {
        Future {
          try await response(
            .refreshRules(.init(appVersion: Current.appVersion)),
            to: RefreshRules.self
          )
          .map { output in .init(
            keyLoggingEnabled: output.keyloggingEnabled,
            screenshotsEnabled: output.screenshotsEnabled,
            screenshotsFrequency: output.screenshotsFrequency,
            screenshotsResolution: output.screenshotsResolution,
            keys: output.keys.map { .init(id: $0.id, type: $0.key) },
            idManifest: output.appManifest
          ) }.get()
        }.eraseToAnyPublisher()
      },

      uploadFilterDecisions: { decisions in
        Task {
          _ = await response(
            .createNetworkDecisions(decisions.map { decision in
              .init(
                id: decision.id,
                verdict: decision.verdict,
                reason: decision.reason,
                ipProtocolNumber: decision.ipProtocol?.int,
                responsibleKeyId: decision.responsibleKeyId,
                hostname: decision.hostname,
                url: decision.url,
                ipAddress: decision.ipAddress,
                appBundleId: decision.bundleId,
                time: decision.createdAt,
                count: decision.count
              )
            }),
            to: CreateNetworkDecisions.self
          )
        }
      },

      uploadKeystrokes: {
        log(.api(.info("upload keystrokes")))
        defer { GlobalKeystrokes.shared.clear() }

        let input: [CreateKeystrokeLines.KeystrokeLineInput] = GlobalKeystrokes.shared.appKeystrokes
          .flatMap {
            appName, keystrokes in
            keystrokes.lines.compactMap { timestamp, line in
              guard let date = keystrokes.lineDates[timestamp] else {
                return nil
              }
              if line.trimmingCharacters(in: .whitespaces).isEmpty {
                return nil
              }
              return .init(appName: appName, line: line, time: date)
            }
          }

        guard !input.isEmpty else {
          return
        }

        Task {
          _ = await response(.createKeystrokeLines(input), to: CreateKeystrokeLines.self)
        }
      },

      uploadScreenshot: { jpegData, width, height, urlCallback in
        Task {
          let output = try await response(
            .createSignedScreenshotUpload(.init(width: width, height: height)),
            to: CreateSignedScreenshotUpload.self
          ).get()
          var uploadRequest = URLRequest(
            url: output.uploadUrl,
            cachePolicy: .reloadIgnoringCacheData
          )
          uploadRequest.httpMethod = "PUT"
          uploadRequest.addValue("public-read", forHTTPHeaderField: "x-amz-acl")
          uploadRequest.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")

          let uploadTask = URLSession.shared.uploadTask(with: uploadRequest, from: jpegData) {
            _, _, error in
            guard error == nil else {
              log(.api(.error("error uploading screenshot", error)))
              urlCallback?(nil)
              return
            }
            urlCallback?(output.webUrl.absoluteString)
            log(.api(.debug("uploaded screenshot to \(output.webUrl.absoluteString)")))
          }
          uploadTask.resume()
          log(.api(.receivedResponse("CreateSignedScreenshotUpload")))
        }
      }
    )
  }
}

// helpers

extension Future where Failure == ApiClient.Error {
  convenience init(operation: @escaping () async throws -> Output) {
    self.init { promise in
      Task {
        do {
          let output = try await operation()
          promise(.success(output))
        } catch {
          if let apiError = error as? ApiClient.Error {
            promise(.failure(apiError))
          } else {
            promise(.failure(.generic("Unknown", error)))
          }
        }
      }
    }
  }
}
