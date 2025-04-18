import LibRecorder
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
  var proxy = SampleHandlerProxy()

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
}
