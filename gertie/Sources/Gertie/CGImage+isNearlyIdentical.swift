#if canImport(Accelerate)
  import Accelerate

  public extension CGImage {
    func isNearlyIdenticalTo(_ other: CGImage?) -> Bool {

      guard let other,
            width == other.width,
            height == other.height,
            let data = bytes,
            let otherData = other.bytes,
            data.count == otherData.count else {
        return false
      }

      return self.meanAbsoluteDifference(data, otherData) < 0.001
    }

    private func meanAbsoluteDifference(_ data1: Data, _ data2: Data) -> Float {
      let length = data1.count

      // Convert the byte arrays to Float
      var floatArray1 = [Float](repeating: 0.0, count: length)
      var floatArray2 = [Float](repeating: 0.0, count: length)
      vDSP.convertElements(of: [UInt8](data1), to: &floatArray1)
      vDSP.convertElements(of: [UInt8](data2), to: &floatArray2)

      // Calculate the average difference of the two images
      let mean = vDSP.mean(vDSP.absolute(vDSP.subtract(floatArray1, floatArray2)))

      // Normalize the output
      return mean / 255.0
    }
  }
#endif
