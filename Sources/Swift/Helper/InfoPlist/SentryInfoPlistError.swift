enum SentryInfoPlistError: Error {
    case mainInfoPlistNotFound
    case keyNotFound(key: String)
    case unableToCastValue(key: String, valueDescription: String, typeDescription: String)
}
