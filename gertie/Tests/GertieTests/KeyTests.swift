import Gertie
import XCore
import XCTest
import XExpect

final class KeyTests: XCTestCase {
  func testConstructingValidKeyDomains() {
    let validInputs = ["foo.com", "www.hondros.com/"]
    for input in validInputs {
      expect(Key.Domain(input)).not.toBeNil()
    }
  }

  func testConstructingInvalidKeyDomains() {
    let validInputs = ["nope bad", "foo.com/baz"]
    for input in validInputs {
      expect(Key.Domain(input)).toBeNil()
    }
  }

  func testKeyDomainStripsScheme() {
    expect(Key.Domain("https://foo.com").string).toEqual("foo.com")
    expect(Key.Domain("http://foo.com").string).toEqual("foo.com")
    expect(Key.Domain("httpwizards.com").string).toEqual("httpwizards.com")
  }

  func testKeyDomainRemovesTrailingSlash() {
    expect(Key.Domain("https://foo.com/").string).toEqual("foo.com")
  }

  func testConstructingValidKeyDomainRegexPatterns() {
    let validInputs = ["deploy--*--foo.com"]
    for input in validInputs {
      expect(Key.DomainRegexPattern(input)).not.toBeNil()
    }
  }

  func testConstructingInvalidKeyDomainRegexPatterns() {
    let validInputs = ["deploy--33--foo.com", "nope bad *", "nope bad"]
    for input in validInputs {
      expect(Key.DomainRegexPattern(input)).toBeNil()
    }
  }

  func testConstructingValidKeyPaths() {
    let validInputs = ["site.com/foo", "site.com/foo/bar"]
    for input in validInputs {
      expect(Key.Path(input)).not.toBeNil()
    }

    let path1 = Key.Path("site.com/foo")
    expect(path1.domain.string).toEqual("site.com")
    expect(path1.path).toEqual("foo")

    let path2 = Key.Path("site.com/foo/bar")
    expect(path2.domain.string).toEqual("site.com")
    expect(path2.path).toEqual("foo/bar")
  }

  func testConstructingInvalidKeyPaths() {
    let validInputs = ["site.com", "nope foo/bar"]
    for input in validInputs {
      expect(Key.Path(input)).toBeNil()
    }
  }

  func testKeyPathMatching() {
    let cases = [
      ("github.com/htc/*", "https://github.com/htc/monkey", true),
      ("github.com/htc/*", "http://github.com/htc/monkey", true),
      ("github.com/htc", "https://github.com/htc/monkey", false),
      ("github.com/htc", "https://github.com/htc", true),
      ("github.com/htc", "https://github.com/htc/", true),
      ("github.com/htc/*/baz", "http://github.com/htc/monkey", false),
      ("github.com/htc/*/baz", "http://github.com/htc/foo/baz", true),
      ("github.com/htc/*/baz", "http://github.com/htc/foo/bar/lol/baz", true),
    ]
    for (path, url, isMatch) in cases {
      let keyPath = Key.Path(path)!
      expect(keyPath.matches(url: url)).toEqual(isMatch)
    }
  }

  func testConstructingValidKeyIps() {
    let validInputs = [
      "1.2.3.4",
      "255.255.255.255",
      "FE80:0000:0000:0000:0202:B3FF:FE1E:8329",
      "FE80::0202:B3FF:FE1E:8329",
      "FE80::0202:B3FF:FE1E:8329%en0",
      // ipv6 localhost
      "0:0:0:0:0:0:0:1", "::1",
    ]
    for input in validInputs {
      expect(Key.Ip(input)).not.toBeNil()
    }
  }

  func testConstructingInvalidKeyIps() {
    let validInputs = ["nope", "", "1.2:3:4", "FE1:0202.3.4"]
    for input in validInputs {
      expect(Key.Ip(input)).toBeNil()
    }
  }

  func testJsonCodingKeys() {
    let cases: [(Key, String)] = [
      (
        Key.ipAddress(ipAddress: "1.2.3.4", scope: .unrestricted),
        """
        {
          "ipAddress": "1.2.3.4",
          "scope": {
            "type": "unrestricted"
          },
          "type": "ipAddress"
        }
        """
      ),
      (
        Key.path(path: "foo.com/safe/path", scope: .unrestricted),
        """
        {
          "path": "foo.com/safe/path",
          "scope": {
            "type": "unrestricted"
          },
          "type": "path"
        }
        """
      ),
      (
        Key.domainRegex(pattern: "foo--*bar.foo.com", scope: .unrestricted),
        """
        {
          "pattern": "foo--*bar.foo.com",
          "scope": {
            "type": "unrestricted"
          },
          "type": "domainRegex"
        }
        """
      ),
      (
        Key.skeleton(scope: .identifiedAppSlug("foo-app")),
        """
        {
          "scope": {
            "identifiedAppSlug": "foo-app",
            "type": "identifiedAppSlug"
          },
          "type": "skeleton"
        }
        """
      ),
      (
        Key.skeleton(scope: .bundleId("com.foo")),
        """
        {
          "scope": {
            "bundleId": "com.foo",
            "type": "bundleId"
          },
          "type": "skeleton"
        }
        """
      ),
      (
        Key.anySubdomain(domain: .init("foo.com")!, scope: .unrestricted),
        """
        {
          "domain": "foo.com",
          "scope": {
            "type": "unrestricted"
          },
          "type": "anySubdomain"
        }
        """
      ),
      (
        Key.domain(domain: .init("foo.com")!, scope: .unrestricted),
        """
        {
          "domain": "foo.com",
          "scope": {
            "type": "unrestricted"
          },
          "type": "domain"
        }
        """
      ),
      (
        Key.domain(domain: .init("foo.com")!, scope: .webBrowsers),
        """
        {
          "domain": "foo.com",
          "scope": {
            "type": "webBrowsers"
          },
          "type": "domain"
        }
        """
      ),
      (
        Key.domain(domain: .init("foo.com")!, scope: .single(.bundleId("foo"))),
        """
        {
          "domain": "foo.com",
          "scope": {
            "single": {
              "bundleId": "foo",
              "type": "bundleId"
            },
            "type": "single"
          },
          "type": "domain"
        }
        """
      ),
    ]

    for (key, jsonString) in cases {
      expect(jsonPretty(key)).toEqual(jsonString)
      expect(decode(jsonString)).toEqual(key)
    }
  }

  func testJsonEncodingAppScope() {
    let cases: [(AppScope, String)] = [
      (
        .unrestricted,
        """
        {
          "type": "unrestricted"
        }
        """
      ),
      (
        .webBrowsers,
        """
        {
          "type": "webBrowsers"
        }
        """
      ),
      (
        .single(.bundleId("com.foo")),
        """
        {
          "single": {
            "bundleId": "com.foo",
            "type": "bundleId"
          },
          "type": "single"
        }
        """
      ),
      (
        .single(.identifiedAppSlug("foo")),
        """
        {
          "single": {
            "identifiedAppSlug": "foo",
            "type": "identifiedAppSlug"
          },
          "type": "single"
        }
        """
      ),
    ]
    for (scope, jsonString) in cases {
      expect(jsonPretty(scope)).toEqual(jsonString)
      expect(decode(jsonString)).toEqual(scope)
    }
  }
}

// helpers

private func decode<T: Decodable>(_ string: String) -> T {
  let decoder = JSONDecoder()
  return try! decoder.decode(T.self, from: string.data(using: .utf8)!)
}

private func jsonPretty<T: Encodable>(_ value: T) -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
  let data = try! encoder.encode(value)
  return String(data: data, encoding: .utf8)!
    .regexReplace(" : ", ": ")
    .regexRemove(#"\\"#)
}
