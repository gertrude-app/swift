import CoreGraphics

extension MenuBar.State.Screen {
  var viewDimensions: (width: CGFloat, height: CGFloat) {
    switch self {
    case .notConnected:
      return (width: 245, height: 60)
    case .connected(let connected):
      return connected.viewDimensions
    }
  }
}

extension MenuBar.State.Connected {
  var viewDimensions: (width: CGFloat, height: CGFloat) {
    var height: CGFloat
    switch (recordingScreen, recordingKeystrokes) {
    case (true, true):
      height = 210
    case (true, false), (false, true):
      height = 186
    case(false, false):
      height = 144
    }

    if filterState != .off {
      height += 28
    }

    if case .suspended = filterState {
      height += 26
    }

    return (width: 310, height: height)
  }
}
