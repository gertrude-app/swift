import LibRecorder
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler, FinishableBroadcast {

  lazy var proxy = SampleHandlerProxy(finisher: self)

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    self.proxy.broadcastStarted(withSetupInfo: setupInfo)
  }

  override func broadcastPaused() {
    self.proxy.broadcastPaused()
  }

  override func broadcastResumed() {
    self.proxy.broadcastResumed()
  }

  override func broadcastFinished() {
    self.proxy.broadcastFinished()
  }

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer,
    with sampleBufferType: RPSampleBufferType
  ) {
    switch sampleBufferType {
    case .video:
      if self.proxy.shouldUploadBuffer() {
        self.proxy.processVideoBufferForUpload(sampleBuffer)
      }
    default:
      break
    }
  }

  // FinishableBroadcast Protocol conformance
  func finishWithError(_ error: any Error) {
    self.finishBroadcastWithError(error)
  }

  // Hook into RPBroadcastSampleHandler's handling of the error.
  override func finishBroadcastWithError(_ error: any Error) {
    super.finishBroadcastWithError(error)
  }
}
