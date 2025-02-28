import XCore
import XCTest

final class BytesTest: XCTestCase {
  func testHumanReadable_BinaryPrefix() {
    let cases: [Int: String] = [
      1: "1 byte",
      333: "333 bytes",
      1000: "1000 bytes",
      1025: "1.0 KiB",
      Bytes.inMebibyte: "1.0 MiB",
      Bytes.inMebibyte + (Bytes.inMebibyte / 2): "1.5 MiB",
      Bytes.inMebibyte * 2: "2.0 MiB",
      Bytes.inGibibyte: "1.0 GiB",
      Bytes.inGibibyte * 2: "2.0 GiB",
    ]
    for (bytes, expected) in cases {
      XCTAssertEqual(Bytes.humanReadable(bytes, prefix: .binary), expected)
    }
  }

  func testHumanReadable_DecimalPrefix() {
    let cases: [Int: String] = [
      1: "1 byte",
      333: "333 bytes",
      1000: "1.0 KB",
      1025: "1.0 KB",
      1100: "1.1 KB",
      Bytes.inMegabyte: "1.0 MB",
      Bytes.inMegabyte + (Bytes.inMegabyte / 2): "1.5 MB",
      Bytes.inMegabyte * 2: "2.0 MB",
      Bytes.inGigabyte: "1.0 GB",
      Bytes.inGigabyte * 2: "2.0 GB",
    ]
    for (bytes, expected) in cases {
      XCTAssertEqual(Bytes.humanReadable(bytes, prefix: .decimal), expected)
    }
  }

  func testHumanReadableSpecifyingDecimalPlaces() {
    let cases: [(bytes: Int, places: Int, expected: String)] = [
      (1025, 0, "1 KiB"),
      (1025, 1, "1.0 KiB"),
      (1025, 2, "1.00 KiB"),
      (1025, 3, "1.001 KiB"),
      (1025, 4, "1.0010 KiB"),
      (1025, 5, "1.00098 KiB"),
      (1025, 6, "1.000977 KiB"),
      (16_106_127_360, 3, "15.000 GiB"),
      (16_408_427_999, 3, "15.282 GiB"),
    ]

    for (bytes, places, expected) in cases {
      XCTAssertEqual(Bytes.humanReadable(bytes, decimalPlaces: places, prefix: .binary), expected)
    }
  }
}
