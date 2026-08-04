import Foundation

/// Sacred-geometry silhouette a Daemon is rendered around. Tied to `Tier` so the
/// power level reads visually. The App maps these to actual shapes/art.
public enum SigilShape: String, Codable, CaseIterable, Sendable {
    case spark      // a point — smallest
    case arrow      // a line/arrow — directional worker
    case triangle   // focused specialist
    case hexagon    // coordinator of many
    case mandala    // a whole nested system — prime

    /// Number of symmetry points, useful for procedural art assembly.
    public var symmetry: Int {
        switch self {
        case .spark:    return 1
        case .arrow:    return 2
        case .triangle: return 3
        case .hexagon:  return 6
        case .mandala:  return 12
        }
    }
}
