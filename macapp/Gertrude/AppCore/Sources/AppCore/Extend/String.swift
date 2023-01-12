extension String {
  func truncate(ifLongerThan maxLength: Int, with: String = "") -> String {
    if count <= maxLength {
      return self
    }
    return prefix(maxLength - with.count) + with
  }
}
