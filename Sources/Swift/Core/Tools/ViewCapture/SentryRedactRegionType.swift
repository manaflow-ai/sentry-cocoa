/// Defines how a region should be handled during session replay redaction.
public enum SentryRedactRegionType: String, Codable, Equatable {
    /// Redacts the region.
    case redact = "redact"

    /// Marks a region to not draw anything.
    /// This is used for opaque views.
    case clipOut = "clip_out"

    /// Push a clip region to the drawing context.
    /// This is used for views that clip to its bounds.
    case clipBegin = "clip_begin"

    /// Pop the last Pushed region from the drawing context.
    /// Used after prossing every child of a view that clip to its bounds.
    case clipEnd = "clip_end"

    /// Redacts the region before ordinary hierarchy-derived regions.
    case priorityRedact = "priority_redact"
}
