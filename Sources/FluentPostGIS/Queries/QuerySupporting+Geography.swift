//
//  File.swift
//  
//
//  Created by Charles Young on 4/29/21.
//

// ST_GeogFromWKB

import FluentSQL
import WKCodable

extension QueryBuilder {
    static func queryExpressionGeography<T: GeometryConvertible>( _ geography: T) -> SQLExpression {
        let geographyText = WKTEncoder().encode(geography.geometry)
        return SQLFunction("ST_GeogFromWKB", args: [SQLLiteral.string(geographyText)])
    }
}
