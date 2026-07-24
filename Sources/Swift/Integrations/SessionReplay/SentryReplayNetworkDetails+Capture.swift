import Foundation

extension SentryReplayNetworkDetails {
    /// Sets request details from raw body data.
    @objc
    public func setRequest(
        size: NSNumber?,
        bodyData: Data?,
        contentType: String?,
        allHeaders: [String: Any]?,
        configuredHeaders: [String]?
    ) {
        let headers = Self.extractHeaders(from: allHeaders, matching: configuredHeaders)
#if SDK_V10
        let sanitizedHeaders = HTTPHeaderSanitizer.sanitizeHeaders(
            headers,
            headerBehavior: .denyList(),
            cookieBehavior: .denyList()
        )
        self.request = Detail(
            size: size,
            body: bodyData.flatMap { Body(data: $0, contentType: contentType) },
            headers: sanitizedHeaders.headers,
            cookies: sanitizedHeaders.cookies
        )
#else
        self.request = Detail(
            size: size,
            body: bodyData.flatMap { Body(data: $0, contentType: contentType) },
            headers: headers
        )
#endif // SDK_V10
    }

#if SDK_V10
    func setRequest(
        size: NSNumber?,
        bodyData: Data?,
        contentType: String?,
        allHeaders: [String: Any]?,
        headerCapture: SentryReplayOptions.NetworkHeaderCapture,
        dataCollection: SentryDataCollection.Options
    ) {
        let sanitizedHeaders = Self.sanitizeHeaders(
            allHeaders,
            capture: headerCapture,
            inheritedBehavior: dataCollection.httpHeaders.request,
            cookieBehavior: dataCollection.cookies
        )
        self.request = Detail(
            size: size,
            body: bodyData.flatMap { Body(data: $0, contentType: contentType) },
            headers: sanitizedHeaders.headers,
            cookies: sanitizedHeaders.cookies
        )
    }
#endif // SDK_V10

    /// Sets response details from raw body data.
    @objc
    public func setResponse(
        statusCode: Int,
        size: NSNumber?,
        bodyData: Data?,
        contentType: String?,
        allHeaders: [String: Any]?,
        configuredHeaders: [String]?
    ) {
        self.statusCode = NSNumber(value: statusCode)
        let headers = Self.extractHeaders(from: allHeaders, matching: configuredHeaders)
#if SDK_V10
        let sanitizedHeaders = HTTPHeaderSanitizer.sanitizeHeaders(
            headers,
            headerBehavior: .denyList(),
            cookieBehavior: .denyList()
        )
        self.response = Detail(
            size: size,
            body: bodyData.flatMap { Body(data: $0, contentType: contentType) },
            headers: sanitizedHeaders.headers,
            cookies: sanitizedHeaders.cookies
        )
#else
        self.response = Detail(
            size: size,
            body: bodyData.flatMap { Body(data: $0, contentType: contentType) },
            headers: headers
        )
#endif // SDK_V10
    }

#if SDK_V10
    func setResponse(
        statusCode: Int,
        size: NSNumber?,
        bodyData: Data?,
        contentType: String?,
        allHeaders: [String: Any]?,
        headerCapture: SentryReplayOptions.NetworkHeaderCapture,
        dataCollection: SentryDataCollection.Options
    ) {
        self.statusCode = NSNumber(value: statusCode)
        let sanitizedHeaders = Self.sanitizeHeaders(
            allHeaders,
            capture: headerCapture,
            inheritedBehavior: dataCollection.httpHeaders.response,
            cookieBehavior: dataCollection.cookies
        )
        self.response = Detail(
            size: size,
            body: bodyData.flatMap { Body(data: $0, contentType: contentType) },
            headers: sanitizedHeaders.headers,
            cookies: sanitizedHeaders.cookies
        )
    }
#endif // SDK_V10

    static func extractHeaders(
        from sourceHeaders: [String: Any]?,
        matching configuredHeaders: [String]?
    ) -> [String: String] {
        guard let sourceHeaders, let configuredHeaders else { return [:] }

        var extracted = [String: String]()
        for configured in configuredHeaders {
            let lowered = configured.lowercased()
            for (key, value) in sourceHeaders where key.lowercased() == lowered {
                extracted[key] = (value as? String) ?? "\(value)"
                break
            }
        }
        return extracted
    }

#if SDK_V10
    private static func sanitizeHeaders(
        _ sourceHeaders: [String: Any]?,
        capture: SentryReplayOptions.NetworkHeaderCapture,
        inheritedBehavior: SentryDataCollection.KeyValueCollectionBehavior,
        cookieBehavior: SentryDataCollection.KeyValueCollectionBehavior
    ) -> HTTPHeaderSanitizer.SanitizedHeaders {
        switch capture {
        case .inherit:
            return HTTPHeaderSanitizer.sanitizeHeaders(
                stringHeaders(sourceHeaders),
                headerBehavior: inheritedBehavior,
                cookieBehavior: cookieBehavior
            )
        case .headers(let configuredHeaders):
            return HTTPHeaderSanitizer.sanitizeHeaders(
                extractHeaders(from: sourceHeaders, matching: configuredHeaders),
                headerBehavior: .denyList(),
                cookieBehavior: .denyList()
            )
        }
    }

    private static func stringHeaders(_ headers: [String: Any]?) -> [String: String] {
        headers?.reduce(into: [:]) { result, entry in
            result[entry.key] = (entry.value as? String) ?? "\(entry.value)"
        } ?? [:]
    }
#endif // SDK_V10

    /// Serializes to dictionary for inclusion in breadcrumb data.
    @objc public func serialize() -> [String: Any] {
        var result = [String: Any]()
        if let method { result["method"] = method }
        if let statusCode { result["statusCode"] = statusCode }
        if let requestBodySize { result["requestBodySize"] = requestBodySize }
        if let responseBodySize { result["responseBodySize"] = responseBodySize }
        if let request { result["request"] = request.serialize() }
        if let response { result["response"] = response.serialize() }
        return result
    }
}
