import Foundation

/// Kind of farm work an activity represents — drives the icon and accent
/// color shown for it across Dashboard, Calendar, and Reports.
enum FarmActivityCategory: String, CaseIterable, Codable {
    case watering    = "Watering"
    case fertilizing = "Fertilizing"
    case care        = "Care"
    case harvest     = "Harvest"
    case planting    = "Planting"

    var displayName: String {
        switch self {
        case .watering:    return L("activityCategory.watering")
        case .fertilizing: return L("activityCategory.fertilizing")
        case .care:        return L("activityCategory.care")
        case .harvest:     return L("activityCategory.harvest")
        case .planting:    return L("activityCategory.planting")
        }
    }

    var systemImage: String {
        switch self {
        case .watering:    return "drop.fill"
        case .fertilizing: return "cross.vial.fill"
        case .care:        return "hand.raised.fill"
        case .harvest:     return "shippingbox.fill"
        case .planting:    return "leaf.fill"
        }
    }
}

struct FarmActivity: Identifiable, Codable {
    var id: UUID
    var title: String
    var date: Date
    var note: String
    var isCompleted: Bool
    var category: FarmActivityCategory
    /// User-picked photo (JPEG), optional — added for `AddEditActivityView`'s
    /// photo picker. Backed by a new optional Core Data attribute, so older
    /// activities (which never had one) just decode/load as `nil`.
    var photoData: Data?
    /// When this activity was marked done — set when `isCompleted` turns
    /// `true`, cleared when undone. Backed by a new optional Core Data
    /// attribute (lightweight-migrated, like `photoData` before it), so
    /// activities completed before this existed just show `nil`.
    var completedAt: Date?

    init(id: UUID = UUID(), title: String, date: Date = Date(),
         note: String = "", isCompleted: Bool = false,
         category: FarmActivityCategory = .watering, photoData: Data? = nil,
         completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.note = note
        self.isCompleted = isCompleted
        self.category = category
        self.photoData = photoData
        self.completedAt = completedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, note, isCompleted, category, photoData, completedAt
    }

    /// Custom decoding so backup JSON files written before `category`,
    /// `photoData`, or `completedAt` existed (no such keys) still restore,
    /// defaulting to `.watering` / `nil` / `nil` respectively.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decode(String.self, forKey: .note)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        category = try container.decodeIfPresent(FarmActivityCategory.self, forKey: .category) ?? .watering
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
}
