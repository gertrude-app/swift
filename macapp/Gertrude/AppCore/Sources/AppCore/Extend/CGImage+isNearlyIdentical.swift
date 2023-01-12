import Foundation

extension CGImage {
  func isNearlyIdenticalTo(_ other: CGImage) -> Bool {
    guard width == other.width,
          height == other.height,
          let data = bytes,
          let otherData = other.bytes,
          data.count == otherData.count else {
      return false
    }

    var numDifferent = 0

    // speed sanity check, sample 1% of the pixels below the menu bar,
    // if we get more than 2 unique, very unlikely to be an identical image
    for index in stride(
      from: width * MENU_BAR_MAX_HEIGHT * BYTES_PER_PIXEL,
      to: data.count,
      by: data.count / BYTES_PER_PIXEL / 100
    ) {
      if data[index] != otherData[index] ||
        data[index + 1] != otherData[index + 1] ||
        // don't check 4th (alpha) byte
        data[index + 2] != otherData[index + 2] {
        numDifferent += 1
        if numDifferent == 2 {
          return false
        }
      }
    }

    // restart after sanity check
    numDifferent = 0

    // second, examine the small square where the clock would be, if visible
    for rowOffset in 0 ..< MENU_BAR_MAX_HEIGHT {
      for colOffset in (width - CLOCK_MAX_EDGE_OFFSET) ..< width {
        let index = (rowOffset * width * BYTES_PER_PIXEL) + (colOffset * BYTES_PER_PIXEL)
        if data[index] != otherData[index] ||
          data[index + 1] != otherData[index + 1] ||
          data[index + 2] != otherData[index + 2] {
          numDifferent += 1
          if numDifferent >= MAX_DIFFERENT_PIXELS_IN_CLOCK_AREA {
            return false
          }
        }
      }
    }

    // we don't differing pixels in clock area so start fresh here
    numDifferent = 0

    // next move to the middle, differences most likely to appear there
    for index in stride(
      from: data.count / 2,
      to: data.count,
      by: BYTES_PER_PIXEL * 2 // outside of clock area, we sample 50% of pixels, for speed
    ) {
      if data[index] != otherData[index] ||
        data[index + 1] != otherData[index + 1] ||
        data[index + 2] != otherData[index + 2] {
        numDifferent += 1
        if numDifferent >= MAX_DIFFERENT_PIXELS_NON_CLOCK_AREA {
          return false
        }
      }
    }

    let menuBarOffset = (width * MENU_BAR_MAX_HEIGHT) * BYTES_PER_PIXEL

    // examine from below menu bar to middle
    for index in stride(from: menuBarOffset, to: data.count / 2, by: BYTES_PER_PIXEL * 2) {
      if data[index] != otherData[index] ||
        data[index + 1] != otherData[index + 1] ||
        data[index + 2] != otherData[index + 2] {
        numDifferent += 1
        if numDifferent >= MAX_DIFFERENT_PIXELS_NON_CLOCK_AREA {
          return false
        }
      }
    }

    // finally, examine menu bar, except for the clock area
    for rowOffset in 0 ..< MENU_BAR_MAX_HEIGHT {
      for colOffset in stride(
        from: 0,
        to: width - CLOCK_MAX_EDGE_OFFSET,
        by: BYTES_PER_PIXEL * 2
      ) {
        let index = (rowOffset * width * BYTES_PER_PIXEL) + (colOffset * BYTES_PER_PIXEL)
        if data[index] != otherData[index] ||
          data[index + 1] != otherData[index + 1] ||
          data[index + 2] != otherData[index + 2] {
          numDifferent += 1
          if numDifferent >= MAX_DIFFERENT_PIXELS_NON_CLOCK_AREA {
            return false
          }
        }
      }
    }

    return true
  }
}

private let MENU_BAR_MAX_HEIGHT = 36
private let CLOCK_MAX_EDGE_OFFSET = 150
private let MAX_DIFFERENT_PIXELS_NON_CLOCK_AREA = 40
// should allow up to `11:50 AM` -> `12:00 PM`
private let MAX_DIFFERENT_PIXELS_IN_CLOCK_AREA = 370
