import FluentSQL
import WKCodable

extension QueryBuilder {
    @discardableResult
    public func filterGeometryDistance<F,V>(_ field: KeyPath<Model, F>, _ filter: V,
                                            _ method: SQLBinaryOperator, _ value: Double, useGeography : Bool = false) -> Self
        where F: QueryableProperty, V: GeometryConvertible
    {
        let expression = useGeography ? QueryBuilder.queryExpressionGeography(filter) : QueryBuilder.queryExpressionGeometry(filter)
        return queryFilterGeometryDistance(QueryBuilder.path(field), expression,
                                           method, SQLLiteral.numeric(String(value)))
    }
    
    @discardableResult
    public func filterGeographyDistance<F,V>(_ field: KeyPath<Model, F>, _ filter: V,
                                            _ method: SQLBinaryOperator, _ value: Double) -> Self
        where F: QueryableProperty, V: GeometryConvertible
    {
        return filterGeometryDistance(field, filter, method, value, useGeography: true)
    }
}

extension QueryBuilder {
    public func queryFilterGeometryDistance(_ path: String, _ filter: SQLExpression,
                                            _ method: SQLBinaryOperator, _ value: SQLExpression) -> Self {
        query.filters.append(.sql(SQLFunction("ST_Distance", args: [SQLColumn(path), filter]),
                                  method, value))
        return self
    }
}
