import SwiftUI

/// A lightweight Identifiable wrapper for String values to use with APIs like `alert(item:)` or `sheet(item:)`
public struct IdentifiableString: Identifiable, Equatable {
    public let id: UUID
    public var value: String

    public init(id: UUID = UUID(), value: String) {
        self.id = id
        self.value = value
    }
}

public extension Binding where Value == String? {
    /// Maps a Binding<String?> to Binding<IdentifiableString?> so it can be used with `alert(item:)`/`sheet(item:)`.
    func asIdentifiable() -> Binding<IdentifiableString?> {
        Binding<IdentifiableString?>(
            get: {
                if let s = self.wrappedValue {
                    return IdentifiableString(value: s)
                } else {
                    return nil
                }
            },
            set: { newValue in
                self.wrappedValue = newValue?.value
            }
        )
    }
}
