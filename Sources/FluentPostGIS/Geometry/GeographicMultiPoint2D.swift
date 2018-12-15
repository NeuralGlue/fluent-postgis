import Foundation
import PostgreSQL
import WKCodable

public struct GeographicMultiPoint2D: Codable, Equatable, CustomStringConvertible, PostgreSQLDataConvertible {
    /// The points
    public var points: [GeographicPoint2D]
    
    /// Create a new `GISGeographicLineString2D`
    public init(points: [GeographicPoint2D]) {
        self.points = points
    }
}

extension GeographicMultiPoint2D: GeometryConvertible {
    /// Convertible type
    public typealias GeometryType = MultiPoint
    
    public init(geometry lineString: GeometryType) {
        let points = lineString.points.map { GeographicPoint2D(geometry: $0) }
        self.init(points: points)
    }
    
    public var geometry: GeometryType {
        return .init(points: self.points.map { $0.geometry }, srid: FluentPostGISSrid)
    }
}

extension GeographicMultiPoint2D: PostgreSQLDataTypeStaticRepresentable, ReflectionDecodable {
    
    /// See `PostgreSQLDataTypeStaticRepresentable`.
    public static var postgreSQLDataType: PostgreSQLDataType { return .geographicMultiPoint }
    
    /// See `ReflectionDecodable`.
    public static func reflectDecoded() throws -> (GeographicMultiPoint2D, GeographicMultiPoint2D) {
        return (.init(points: []), .init(points: [GeographicPoint2D(longitude: 0, latitude: 0)]))
    }
}
