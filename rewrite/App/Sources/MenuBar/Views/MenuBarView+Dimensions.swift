import CoreGraphics

extension MenuBar.State {
  var viewDimensions: (width: CGFloat, height: CGFloat) {
    user?.viewDimensions ?? (width: 245, height: 60)
  }
}

extension MenuBar.State.User {
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

    if filterRunning {
      height += 28
    }

    if filterSuspension?.isActive == true {
      height += 26
    }

    return (width: 310, height: height)
  }
}
