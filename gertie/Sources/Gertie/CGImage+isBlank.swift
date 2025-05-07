#if canImport(CoreGraphics)
  import CoreGraphics
  import Foundation

  typealias Pixel = (UInt8, UInt8, UInt8, UInt8)
  let BYTES_PER_PIXEL = 4

  public extension CGImage {
    var bytes: Data? {
      guard let provider = dataProvider, let bytes = provider.data as Data? else {
        return nil
      }
      return bytes
    }

    var isBlank: Bool {
      guard let data = bytes, data.count >= BYTES_PER_PIXEL else {
        return false
      }

      let reference = (data[0], data[1], data[2], data[3])
      if !pixels(in: data, equal: reference, striding: 1000) {
        return false
      }
      if !pixels(in: data, equal: reference, striding: 100) {
        return false
      }
      // at most, check 50% of pixels
      if !pixels(in: data, equal: reference, striding: BYTES_PER_PIXEL * 2) {
        return false
      }
      return true
    }
  }

  // helpers

  private func pixels(in data: Data, equal reference: Pixel, striding distance: Int) -> Bool {
    for index in stride(from: BYTES_PER_PIXEL, to: data.count - BYTES_PER_PIXEL, by: distance) {
      if data[index] != reference.0 ||
        data[index + 1] != reference.1 ||
        data[index + 2] != reference.2 { // don't check 4th byte, it's alpha and is always 255
        return false
      }
    }
    return true
  }
#endif
