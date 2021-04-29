import FluentSQL
import WKCodable

extension QueryBuilder {
    static func queryExpressionGeometry<T: GeometryConvertible>(_ geometry: T) -> SQLExpression {
        let geometryText = WKTEncoder().encode(geometry.geometry)
        return SQLFunction("ST_GeomFromEWKT", args: [SQLLiteral.string(geometryText)])
    }
    
//    private static func key(_ key: FieldKey) -> String {
//        switch key {
//        case .id:
//            return "id"
//        case .string(let name):
//            return name
//        case .aggregate:
//            return key.description
//        }
//    }
    
    static func path<F>(_ field: KeyPath<Model, F>) -> String where F: QueryableProperty {
        return Model.path(for: field).map(\.description).joined(separator: "_")
    }
}

extension QueryBuilder {
    func applyFilter(function: String, args: [SQLExpression]) {
        query.filters.append(.custom(SQLFunction(function, args: args)))
    }
    
    func applyFilter(function: String, path: String, value: SQLExpression) {
        applyFilter(function: function, args: [SQLColumn(path), value])
    }
    
    func applyFilter(function: String, value: SQLExpression, path: String) {
        applyFilter(function: function, args: [value, SQLColumn(path)])
    }
}
