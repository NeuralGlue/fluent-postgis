import XCTest
import FluentKit
import FluentBenchmark
import FluentPostgresDriver
import PostgresKit
import Foundation
@testable import FluentPostGIS

final class QueryTests: XCTestCase {
    var eventLoopGroup: EventLoopGroup!
    var threadPool: NIOThreadPool!
    var dbs: Databases!
    var conn: Database {
        self.dbs.database(
            logger: .init(label: "lib.fluent.postgis"),
            on: self.dbs.eventLoopGroup.next()
        )!
    }
    var postgres: PostgresDatabase {
        self.conn as! PostgresDatabase
    }

    override func setUp() {
        let configuration = PostgresConfiguration(
            hostname: "localhost",
            username: "fluentpostgis",
            password: "fluentpostgis",
            database: "postgis_tests"
        )

        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.threadPool = NIOThreadPool(numberOfThreads: 1)
        self.dbs = Databases(threadPool: threadPool, on: self.eventLoopGroup)
        self.dbs.use(.postgres(configuration: configuration), as: .psql)
    }
    
    func testContains() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }
        
        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)
        
        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()
        
        let testPoint = GeometricPoint2D(x: 5, y: 5)
        let all = try UserArea.query(on: conn).filterGeometryContains(\.$area, testPoint).all().wait()
        XCTAssertEqual(all.count, 1)
    }
    
    func testContainsReversed() throws {
        try UserLocationMigration().prepare(on: conn).wait()
        defer { try! UserLocationMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPoint = GeometricPoint2D(x: 5, y: 5)
        let user = UserLocation()
        user.location = testPoint
        _ = try user.save(on: conn).wait()

        let all = try UserLocation.query(on: conn).filterGeometryContains(polygon, \.$location).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testContainsWithHole() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let hole = GeometricLineString2D(points: [
            GeometricPoint2D(x: 2.5, y: 2.5),
            GeometricPoint2D(x: 7.5, y: 2.5),
            GeometricPoint2D(x: 7.5, y: 7.5),
            GeometricPoint2D(x: 2.5, y: 7.5),
            GeometricPoint2D(x: 2.5, y: 2.5)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing, interiorRings: [hole])

        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()

        let testPoint = GeometricPoint2D(x: 5, y: 5)
        let all = try UserArea.query(on: conn).filterGeometryContains(\.$area, testPoint).all().wait()
        XCTAssertEqual(all.count, 0)

        let testPoint2 = GeometricPoint2D(x: 1, y: 5)
        let all2 = try UserArea.query(on: conn).filterGeometryContains(\.$area, testPoint2).all().wait()
        XCTAssertEqual(all2.count, 1)
    }

    func testCrosses() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 5, y: 5)
            ])

        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()

        let all = try UserArea.query(on: conn).filterGeometryCrosses(\.$area, testPath).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testCrossesReversed() throws {
        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 5, y: 5)
            ])

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryCrosses(polygon, \.$path).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testDisjoint() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 11, y: 5)
            ])

        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()

        let all = try UserArea.query(on: conn).filterGeometryDisjoint(\.$area, testPath).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testDisjointReversed() throws {
        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 11, y: 5)
            ])

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryDisjoint(polygon, \.$path).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testEquals() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }
        
        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()

        let all = try UserArea.query(on: conn).filterGeometryEquals(\.$area, polygon).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testIntersects() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 5, y: 5)
            ])

        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()

        let all = try UserArea.query(on: conn).filterGeometryIntersects(\.$area, testPath).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testIntersectsReversed() throws {
        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 5, y: 5)
            ])

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryIntersects(polygon, \.$path).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testOverlaps() throws {

        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 5, y: 5),
            GeometricPoint2D(x: 6, y: 6),
            GeometricPoint2D(x: 0, y: 0),
            ])

        let testPath2 = GeometricLineString2D(points: [
            GeometricPoint2D(x: 16, y: 0),
            GeometricPoint2D(x: 5, y: 5),
            GeometricPoint2D(x: 6, y: 6),
            GeometricPoint2D(x: 2, y: 0),
            ])

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryOverlaps(\.$path, testPath2).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testOverlapsReversed() throws {
        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 15, y: 0),
            GeometricPoint2D(x: 5, y: 5),
            GeometricPoint2D(x: 6, y: 6),
            GeometricPoint2D(x: 0, y: 0),
            ])

        let testPath2 = GeometricLineString2D(points: [
            GeometricPoint2D(x: 16, y: 0),
            GeometricPoint2D(x: 5, y: 5),
            GeometricPoint2D(x: 6, y: 6),
            GeometricPoint2D(x: 2, y: 0),
            ])

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryOverlaps(testPath2, \.$path).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testTouches() throws {
        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 1, y: 1),
            GeometricPoint2D(x: 0, y: 2)
            ])

        let testPoint = GeometricPoint2D(x: 0, y: 2)

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryTouches(\.$path, testPoint).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testTouchesReversed() throws {
        try UserPathMigration().prepare(on: conn).wait()
        defer { try! UserPathMigration().revert(on: conn).wait() }

        let testPath = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 1, y: 1),
            GeometricPoint2D(x: 0, y: 2)
            ])

        let testPoint = GeometricPoint2D(x: 0, y: 2)

        let user = UserPath()
        user.path = testPath
        _ = try user.save(on: conn).wait()

        let all = try UserPath.query(on: conn).filterGeometryTouches(testPoint, \.$path).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testWithin() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)
        let hole = GeometricLineString2D(points: [
            GeometricPoint2D(x: 2.5, y: 2.5),
            GeometricPoint2D(x: 7.5, y: 2.5),
            GeometricPoint2D(x: 7.5, y: 7.5),
            GeometricPoint2D(x: 2.5, y: 7.5),
            GeometricPoint2D(x: 2.5, y: 2.5)])
        let polygon2 = GeometricPolygon2D(exteriorRing: hole)

        let user = UserArea()
        user.area = polygon2
        _ = try user.save(on: conn).wait()

        let all = try UserArea.query(on: conn).filterGeometryWithin(\.$area, polygon).all().wait()
        XCTAssertEqual(all.count, 1)
    }

    func testWithinReversed() throws {
        try UserAreaMigration().prepare(on: conn).wait()
        defer { try! UserAreaMigration().revert(on: conn).wait() }

        let exteriorRing = GeometricLineString2D(points: [
            GeometricPoint2D(x: 0, y: 0),
            GeometricPoint2D(x: 10, y: 0),
            GeometricPoint2D(x: 10, y: 10),
            GeometricPoint2D(x: 0, y: 10),
            GeometricPoint2D(x: 0, y: 0)])
        let polygon = GeometricPolygon2D(exteriorRing: exteriorRing)
        let hole = GeometricLineString2D(points: [
            GeometricPoint2D(x: 2.5, y: 2.5),
            GeometricPoint2D(x: 7.5, y: 2.5),
            GeometricPoint2D(x: 7.5, y: 7.5),
            GeometricPoint2D(x: 2.5, y: 7.5),
            GeometricPoint2D(x: 2.5, y: 2.5)])
        let polygon2 = GeometricPolygon2D(exteriorRing: hole)

        let user = UserArea()
        user.area = polygon
        _ = try user.save(on: conn).wait()

        let all = try UserArea.query(on: conn).filterGeometryWithin(polygon2, \.$area).all().wait()
        XCTAssertEqual(all.count, 1)
    }
}
