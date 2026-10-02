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

    init(id: UUID = UUID(), title: String, date: Date = Date(),
         note: String = "", isCompleted: Bool = false,
         category: FarmActivityCategory = .watering) {
        self.id = id
        self.title = title
        self.date = date
        self.note = note
        self.isCompleted = isCompleted
        self.category = category
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, date, note, isCompleted, category
    }

    /// Custom decoding so backup JSON files written before `category` existed
    /// (no such key) still restore, defaulting to `.watering`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        note = try container.decode(String.self, forKey: .note)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        category = try container.decodeIfPresent(FarmActivityCategory.self, forKey: .category) ?? .watering
    }
}
