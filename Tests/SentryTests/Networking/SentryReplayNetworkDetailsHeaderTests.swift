@_spi(Private) @testable import Sentry
import XCTest

class SentryReplayNetworkDetailsHeaderTests: XCTestCase {

    // MARK: - Header Extraction Tests

    func testExtractHeaders_caseInsensitiveMatching() {
        // -- Arrange --
        let sourceHeaders: [String: Any] = [
            "Content-Type": "application/json",
            "AUTHORIZATION": "Bearer token",
            "x-request-id": "123"
        ]
        let configuredHeaders = ["content-type", "Authorization", "X-Request-ID"]

        // -- Act --
        let extracted = SentryReplayNetworkDetails.extractHeaders(
            from: sourceHeaders,
            matching: configuredHeaders
        )

        // -- Assert --
        XCTAssertEqual(extracted.count, 3)
        // Should preserve original casing from source
        XCTAssertEqual(extracted["Content-Type"], "application/json")
        XCTAssertEqual(extracted["AUTHORIZATION"], "Bearer token")
        XCTAssertEqual(extracted["x-request-id"], "123")
    }

    func testExtractHeaders_withNilInputs_returnsEmptyDict() {
        // Test nil source headers
        XCTAssertEqual(
            SentryReplayNetworkDetails.extractHeaders(from: nil, matching: ["test"]),
            [:]
        )

        // Test nil configured headers
        XCTAssertEqual(
            SentryReplayNetworkDetails.extractHeaders(from: ["test": "value"], matching: nil),
            [:]
        )

        // Test both nil
        XCTAssertEqual(
            SentryReplayNetworkDetails.extractHeaders(from: nil, matching: nil),
            [:]
        )
    }

    func testExtractHeaders_nonStringValues_convertedToStrings() {
        // -- Arrange --
        let sourceHeaders: [String: Any] = [
            "Content-Length": NSNumber(value: 9_876),
            "Retry-After": 60,
            "X-Bool": true,
            "X-Double": 3.14159
        ]
        let configuredHeaders = ["Content-Length", "Retry-After", "X-Bool", "X-Double"]

        // -- Act --
        let extracted = SentryReplayNetworkDetails.extractHeaders(
            from: sourceHeaders,
            matching: configuredHeaders
        )

        // -- Assert --
        XCTAssertEqual(extracted.count, 4)
        XCTAssertEqual(extracted["Content-Length"], "9876")
        XCTAssertEqual(extracted["Retry-After"], "60")
        XCTAssertEqual(extracted["X-Bool"], "true")
        XCTAssertEqual(extracted["X-Double"], "3.14159")
    }

    func testSetRequest_whenHeaderCaptureInherits_shouldUseRequestBehavior() throws {
#if !SDK_V10
        throw XCTSkip("Test skipped for SDK_V10")
#else
        // -- Arrange --
        let details = SentryReplayNetworkDetails(method: "GET")
        let dataCollection = SentryDataCollection.Options(
            httpHeaders: .init(
                request: .allowList(terms: ["request-id"]),
                response: .off
            )
        )

        // -- Act --
        details.setRequest(
            size: nil,
            bodyData: nil,
            contentType: nil,
            allHeaders: [
                "Content-Type": "application/json",
                "X-Auth-Token": "secret-token",
                "X-Request-Id": "request-id"
            ],
            headerCapture: .inherit,
            dataCollection: dataCollection
        )

        // -- Assert --
        XCTAssertEqual(details.request?.headers, [
            "Content-Type": "[Filtered]",
            "X-Auth-Token": "[Filtered]",
            "X-Request-Id": "request-id"
        ])
#endif
    }

    func testSetResponse_whenHeaderCaptureInherits_shouldUseResponseBehaviorIndependently() throws {
#if !SDK_V10
        throw XCTSkip("Test skipped for SDK_V10")
#else
        // -- Arrange --
        let details = SentryReplayNetworkDetails(method: "GET")
        let dataCollection = SentryDataCollection.Options(
            httpHeaders: .init(
                request: .allowList(terms: ["request-id"]),
                response: .off
            )
        )

        // -- Act --
        details.setResponse(
            statusCode: 200,
            size: nil,
            bodyData: nil,
            contentType: nil,
            allHeaders: ["X-Response-Id": "response-id"],
            headerCapture: .inherit,
            dataCollection: dataCollection
        )

        // -- Assert --
        XCTAssertEqual(details.response?.headers, [:])
#endif
    }

    func testSetRequest_whenHeaderCaptureOverridesGlobalOff_shouldSelectHeadersAndFilterSensitiveValues() throws {
#if !SDK_V10
        throw XCTSkip("Test skipped for SDK_V10")
#else
        // -- Arrange --
        let details = SentryReplayNetworkDetails(method: "GET")
        let dataCollection = SentryDataCollection.Options(
            httpHeaders: .init(request: .off, response: .off)
        )

        // -- Act --
        details.setRequest(
            size: nil,
            bodyData: nil,
            contentType: nil,
            allHeaders: [
                "Authorization": "Bearer secret",
                "X-Request-Id": "request-id",
                "X-Unselected": "unselected"
            ],
            headerCapture: .headers(["Authorization", "X-Request-Id"]),
            dataCollection: dataCollection
        )

        // -- Assert --
        XCTAssertEqual(details.request?.headers, [
            "Authorization": "[Filtered]",
            "X-Request-Id": "request-id"
        ])
#endif
    }

    func testSetRequest_whenCookiesAreInherited_shouldParseAndFilterCookieValues() throws {
#if !SDK_V10
        throw XCTSkip("Test skipped for SDK_V10")
#else
        // -- Arrange --
        let details = SentryReplayNetworkDetails(method: "GET")
        let dataCollection = SentryDataCollection.Options(
            cookies: .denyList(),
            httpHeaders: .init(request: .off, response: .off)
        )

        // -- Act --
        details.setRequest(
            size: nil,
            bodyData: nil,
            contentType: nil,
            allHeaders: ["Cookie": "theme=dark; session=secret"],
            headerCapture: .inherit,
            dataCollection: dataCollection
        )

        // -- Assert --
        XCTAssertEqual(details.request?.headers, [:])
        XCTAssertEqual(details.request?.cookies, [
            "session": "[Filtered]",
            "theme": "dark"
        ])
#endif
    }

    func testSetResponse_whenCookieCannotBeParsed_shouldUseFilteredHeaderFallback() throws {
#if !SDK_V10
        throw XCTSkip("Test skipped for SDK_V10")
#else
        // -- Arrange --
        let details = SentryReplayNetworkDetails(method: "GET")

        // -- Act --
        details.setResponse(
            statusCode: 200,
            size: nil,
            bodyData: nil,
            contentType: nil,
            allHeaders: ["Set-Cookie": "opaque-cookie"],
            headerCapture: .inherit,
            dataCollection: SentryDataCollection.Options()
        )

        // -- Assert --
        XCTAssertEqual(details.response?.headers, ["Set-Cookie": "[Filtered]"])
        XCTAssertEqual(details.response?.cookies, [:])
#endif
    }

    func testSetRequest_whenCookieCollectionIsOff_shouldOmitCookies() throws {
#if !SDK_V10
        throw XCTSkip("Test skipped for SDK_V10")
#else
        // -- Arrange --
        let details = SentryReplayNetworkDetails(method: "GET")
        let dataCollection = SentryDataCollection.Options(cookies: .off)

        // -- Act --
        details.setRequest(
            size: nil,
            bodyData: nil,
            contentType: nil,
            allHeaders: ["Cookie": "theme=dark"],
            headerCapture: .inherit,
            dataCollection: dataCollection
        )

        // -- Assert --
        XCTAssertEqual(details.request?.headers, [:])
        XCTAssertEqual(details.request?.cookies, [:])
#endif
    }

    func testExtractHeaders_unconfiguredHeadersAreExcluded() {
        // -- Arrange --
        let sourceHeaders: [String: Any] = [
            "Content-Type": "application/json",
            "Authorization": "Bearer token",
            "X-Custom": "should not appear"
        ]
        let configuredHeaders = ["Content-Type", "Authorization"]

        // -- Act --
        let extracted = SentryReplayNetworkDetails.extractHeaders(
            from: sourceHeaders,
            matching: configuredHeaders
        )

        // -- Assert --
        XCTAssertEqual(extracted.count, 2)
        XCTAssertEqual(extracted["Content-Type"], "application/json")
        XCTAssertEqual(extracted["Authorization"], "Bearer token")
        XCTAssertNil(extracted["X-Custom"])
    }
}
