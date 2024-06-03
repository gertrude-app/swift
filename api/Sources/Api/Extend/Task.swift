extension Task where Success == Never, Failure == Never {
  static func sleep(seconds: Int) async throws {
    // linux requires different import for NSEC_PER_SEC, so hard-code
    try await self.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
  }
}
