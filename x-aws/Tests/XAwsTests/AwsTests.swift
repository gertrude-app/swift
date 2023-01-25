import XCTest
import XExpect

@testable import XAws

final class XAwsTests: XCTestCase {
  func testSignedUrl() {
    let url = AWS.Request.signedUrl(
      httpVerb: .GET,
      endpoint: "s3.amazonaws.com",
      bucket: "examplebucket",
      accessKeyId: "AKIAIOSFODNN7EXAMPLE",
      secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      time: .awsRefDate,
      objectKey: "test.txt",
      expires: 86400
    )

    let expected =
      "https://examplebucket.s3.amazonaws.com/test.txt?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404"

    expect(url).toEqual(expected)
  }

  func testQueryString() {
    let params = [
      "prefix": "somePrefix",
      "marker": "someMarker",
      "max-keys": "20",
    ]

    let expected = "marker=someMarker&max-keys=20&prefix=somePrefix"
    let actual = AWS.Request.queryString(params)
    expect(actual).toEqual(expected)
  }

  func testCanonicalRequestForPreSignedUrl() {
    let expected = """
    GET
    /test.txt
    X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host
    host:examplebucket.s3.amazonaws.com

    host
    UNSIGNED-PAYLOAD
    """

    let request = AWS.Request.canonicalRequestForPreSignedUrl(
      httpVerb: .GET,
      endpoint: "s3.amazonaws.com",
      bucket: "examplebucket",
      accessKeyId: "AKIAIOSFODNN7EXAMPLE",
      time: .awsRefDate,
      objectKey: "test.txt",
      expires: 86400,
      queryParams: [:],
      signedHeaders: [:]
    )

    expect(request).toEqual(expected)
  }

  func testExampleRequestature() {
    let stringToSign = """
    AWS4-HMAC-SHA256
    20130524T000000Z
    20130524/us-east-1/s3/aws4_request
    3bfa292879f6447bbcda7001decf97f4a54dc650c8942174ae0a9121cf58ad04
    """

    let signingKey = AWS.Request.signingKey(
      secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
      time: .awsRefDate
    )

    let signature = AWS.Request.signature(
      signingKey: signingKey,
      stringToSign: stringToSign
    )

    expect(signature).toBe("aeeed9bbccd4d02ee5c0109b86d86835f995330da4c265957d157751f604d404")
  }

  func testStringToSign() {
    let canonicalRequest = """
    GET
    /test.txt
    X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20130524T000000Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host
    host:examplebucket.s3.amazonaws.com

    host
    UNSIGNED-PAYLOAD
    """

    let stringToSign = AWS.Request.stringToSign(
      canonicalRequest: canonicalRequest,
      time: .awsRefDate,
      region: "us-east-1",
      service: "s3"
    )

    expect(stringToSign).toBe("""
    AWS4-HMAC-SHA256
    20130524T000000Z
    20130524/us-east-1/s3/aws4_request
    3bfa292879f6447bbcda7001decf97f4a54dc650c8942174ae0a9121cf58ad04
    """)
  }
}

extension Date {
  static let awsRefDate = Date(timeIntervalSince1970: 1_369_353_600)
}
