import Accelerate

public extension CGImage {
  func isNearlyIdenticalTo(_ other: CGImage?) -> Bool {
    
    guard let other = other,
          width == other.width,
          height == other.height,
          let data = bytes,
          let otherData = other.bytes,
          data.count == otherData.count else {
      return false
    }
    
    return meanAbsoluteDifference(data, otherData) < 0.001
  }
  
  private func meanAbsoluteDifference(_ data1: Data, _ data2: Data) -> Float {
    let length = data1.count
    
    // Convert the byte arrays to Float
    var floatArray1 = [Float](repeating: 0.0, count: length)
    var floatArray2 = [Float](repeating: 0.0, count: length)
    vDSP.convertElements(of: [UInt8](data1), to: &floatArray1)
    vDSP.convertElements(of: [UInt8](data2), to: &floatArray2)
    
    // Allocate storage for the absolute differences
    var differences = [Float](repeating: 0.0, count: length)
    
    // Calculate absolute differences using vDSP
    vDSP_vsub(floatArray1, 1, floatArray2, 1, &differences, 1, vDSP_Length(length))
    vDSP_vabs(differences, 1, &differences, 1, vDSP_Length(length))
    // Calculate the mean of absolute differences
    var mean: Float = 0.0
    vDSP_meanv(differences, 1, &mean, vDSP_Length(length))
    
    // Normalize the output
    return mean / 255.0
  }
  
  
}

