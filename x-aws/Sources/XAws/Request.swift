import Foundation

// see https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
// see https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html

extension AWS.Request {
  private typealias Util = AWS.Util

  enum HttpVerb: String {
    case GET
    case PUT
    case POST
    case DELETE
  }

  static func signedUrl(
    httpVerb: HttpVerb = .PUT,
    endpoint: String = "nyc3.digitaloceanspaces.com",
    bucket: String = "gertrude",
    region: String = "us-east-1",
    service: String = "s3",
    accessKeyId: String,
    secretAccessKey: String,
    time: Date = Date(),
    objectKey: String,
    expires: Int,
    queryParams: [String: String] = [:],
    signedHeaders: [String: String] = [:]
  ) -> String {
    let canonicalRequest = canonicalRequestForPreSignedUrl(
      httpVerb: httpVerb,
      endpoint: endpoint,
      bucket: bucket,
      region: region,
      service: service,
      accessKeyId: accessKeyId,
      time: time,
      objectKey: objectKey,
      expires: expires,
      queryParams: queryParams,
      signedHeaders: signedHeaders
    )
    let stringToSign = stringToSign(
      canonicalRequest: canonicalRequest,
      time: time,
      region: region,
      service: service
    )
    let signingKey = signingKey(
      secretAccessKey: secretAccessKey,
      time: time
    )
    let signature = signature(
      signingKey: signingKey,
      stringToSign: stringToSign
    )
    let (_, params) = data(
      accessKeyId,
      endpoint,
      bucket,
      region,
      service,
      time,
      expires,
      signedHeaders
    )
    return "https://\(bucket).\(endpoint)/\(objectKey)?\(queryString(params))&X-Amz-Signature=\(signature)"
  }

  static func canonicalRequestForPreSignedUrl(
    httpVerb: HttpVerb = .PUT,
    endpoint: String = "nyc3.digitaloceanspaces.com",
    bucket: String = "gertrude",
    region: String = "us-east-1",
    service: String = "s3",
    accessKeyId: String,
    time: Date = Date(),
    objectKey: String,
    expires: Int,
    queryParams: [String: String] = [:],
    signedHeaders: [String: String] = [:]
  ) -> String {
    let (headers, params) = data(
      accessKeyId,
      endpoint,
      bucket,
      region,
      service,
      time,
      expires,
      signedHeaders
    )

    let canonicalUri = Util.uriEncode(objectKey, isObjectKeyName: true)
    let canonicalQueryString = queryString(params)

    return """
    \(httpVerb)
    /\(canonicalUri)
    \(canonicalQueryString)
    \(canonicalHeaders(headers))
    \(Self.signedHeaders(headers))
    UNSIGNED-PAYLOAD
    """
  }

  private static func data(
    _ accessKeyId: String,
    _ endpoint: String = "nyc3.digitaloceanspaces.com",
    _ bucket: String = "gertrude",
    _ region: String = "us-east-1",
    _ service: String = "s3",
    _ time: Date = Date(),
    _ expires: Int,
    _ signedHeaders: [String: String] = [:]
  ) -> (header: [String: String], params: [String: String]) {
    var headers = signedHeaders
    headers["host"] = "\(bucket).\(endpoint)"

    let signedHeadersParam = headers.keys
      .sorted()
      .map { key in key.lowercased() }
      .joined(separator: ";")

    var params: [String: String] = [:]
    let credential = "\(accessKeyId)/\(scope(time, region, service))"
    params["X-Amz-Credential"] = credential
    params["X-Amz-Algorithm"] = "AWS4-HMAC-SHA256"
    params["X-Amz-Date"] = Util.timestamp(time)
    params["X-Amz-Expires"] = String(expires)
    params["X-Amz-SignedHeaders"] = signedHeadersParam
    return (headers, params)
  }

  static func scope(
    _ time: Date = Date(),
    _ region: String = "us-east-1",
    _ service: String = "s3"
  ) -> String {
    "\(Util.yyyymmdd(time))/\(region)/\(service)/aws4_request"
  }

  static func canonicalHeaders(_ headers: [String: String]) -> String {
    headers
      .sorted { $0.key < $1.key }
      .map { key, value in "\(Util.lowercase(key)):\(Util.trim(value))" }
      .joined(separator: "\n") + "\n"
  }

  static func signedHeaders(_ headers: [String: String]) -> String {
    headers
      .sorted { $0.key < $1.key }
      .map { key, _ in Util.lowercase(key) }
      .joined(separator: ";")
  }

  static func queryString(_ queryParams: [String: String]) -> String {
    queryParams
      .sorted { $0.key < $1.key }
      .map { "\(Util.uriEncode($0.key))=\(Util.uriEncode($0.value))" }
      .joined(separator: "&")
  }

  static func stringToSign(
    canonicalRequest: String,
    time: Date = Date(),
    region: String = "us-east-1",
    service: String = "s3"
  ) -> String {
    """
    AWS4-HMAC-SHA256
    \(Util.timestamp(time))
    \(scope(time, region, service))
    \(Util.sha256(canonicalRequest))
    """
  }

  static func signingKey(
    secretAccessKey: String,
    time: Date = Date(),
    region: String = "us-east-1",
    service: String = "s3"
  ) -> Data {
    let dateKey = Util.hmac("AWS4\(secretAccessKey)", Util.yyyymmdd(time))
    let dateRegionKey = Util.hmac(dateKey, region)
    let dateRegionServiceKey = Util.hmac(dateRegionKey, service)
    return Util.hmac(dateRegionServiceKey, "aws4_request")
  }

  static func signature(
    signingKey: Data,
    stringToSign: String
  ) -> String {
    Util.hex(Util.hmac(signingKey, stringToSign))
  }
}

extension AWS {
  enum Request {}
}
