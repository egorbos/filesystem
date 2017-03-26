/// Copyright 2017 Sergei Egorov
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
/// http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import XCTest
import Error
import Foundation

@testable import Filesystem

class FSManagerTests: XCTestCase {

    let fsManager = FSManager()

    fileprivate let workPath = FileManager.default.currentDirectoryPath
    fileprivate var testDirectoryPath: String {
        return "\(workPath)/testdirectory"
    }
    fileprivate var testFilePath: String {
        return "\(testDirectoryPath)/file"
    }

    static var allTests : [(String, (FSManagerTests) -> () throws -> Void)] {
        return [
            ("testObjectExist", testObjectExist),
            ("testGetObjectAttributes", testGetObjectAttributes),
            ("testGetAttributesOfNonExistsObject", testGetAttributesOfNonExistsObject),
            ("testGetPermissionsForObject", testGetPermissionsForObject),
            ("testGetContentsOfDirectory", testGetContentsOfDirectory),
            ("testGetContentsOfNonExistsDirectory", testGetContentsOfNonExistsDirectory),
            ("testCreateSymbolicLinkWithoutDestinationObjectName", testCreateSymbolicLinkWithoutDestinationObjectName),
            ("testCreateSymbolicLinkWithDestinationObjectName", testCreateSymbolicLinkWithDestinationObjectName),
            ("testCreateSymbolicLinkOfNonExistsObject", testCreateSymbolicLinkOfNonExistsObject),
            ("testCreateHardLinkWithoutDestinationObjectName", testCreateHardLinkWithoutDestinationObjectName),
            ("testCreateHardLinkWithDestinationObjectName", testCreateHardLinkWithDestinationObjectName),
            ("testCreateHardLinkOfNonExistsObject", testCreateHardLinkOfNonExistsObject),
            ("testDeleteObject", testDeleteObject),
            ("testMoveObjectWithoutDestinationObjectName", testMoveObjectWithoutDestinationObjectName),
            ("testMoveObjectWithDestinationObjectName", testMoveObjectWithDestinationObjectName),
            ("testMoveNonExistsObject", testMoveNonExistsObject),
            ("testCopyObjectWithoutDestinationObjectName", testCopyObjectWithoutDestinationObjectName),
            ("testCopyObjectWithDestinationObjectName", testCopyObjectWithDestinationObjectName),
            ("testCopyNonExistsObject", testCopyNonExistsObject),
            ("testCreateDirectory", testCreateDirectory),
            ("testCreateDirectoryWhichIsAlreadyExists", testCreateDirectoryWhichIsAlreadyExists)
        ]
    }

    override func setUp() {
        super.setUp()
        do {
            try fsManager.createDirectory(atPath: testDirectoryPath)
        } catch let error as SomeError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }

        XCTAssertTrue(fsManager.existsObject(atPath: testDirectoryPath))
    }

    override func tearDown() {
        deleteObject(atPath: testDirectoryPath)
        super.tearDown()
    }

    // MARK: - Helpers

    fileprivate func deleteObject(atPath path: String) {
        do {
            try fsManager.deleteObject(atPath: path)
        } catch let error as SomeError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }
    }

    fileprivate func createDirectory(atPath path: String) {
        do {
            try fsManager.createDirectory(atPath: path)
        } catch let error as SomeError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }
    }

    // MARK: - Tests

    func testObjectExist() {
        XCTAssertFalse(fsManager.existsObject(atPath: testFilePath))
        fsManager.createFile(atPath: testFilePath, content: nil)

        XCTAssertTrue(fsManager.existsObject(atPath: testFilePath))
        deleteObject(atPath: testFilePath)
    }

    func testGetObjectAttributes() throws {
        var attributes: [String : AnyHashable]?
        XCTAssertThrowsError(try fsManager.attributesOfObject(atPath: testFilePath))
        fsManager.createFile(atPath: testFilePath, content: nil)

        attributes = try fsManager.attributesOfObject(atPath: testFilePath)

        XCTAssertNotNil(attributes)
        deleteObject(atPath: testFilePath)
    }

    func testGetAttributesOfNonExistsObject() {
        XCTAssertThrowsError(try fsManager.attributesOfObject(atPath: "/Foo/bar"))
    }

    func testGetPermissionsForObject() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)

        XCTAssertTrue(fsManager.isReadableObject(atPath: testFilePath))
        XCTAssertTrue(fsManager.isWritableObject(atPath: testFilePath))
        XCTAssertFalse(fsManager.isExecutableObject(atPath: testFilePath))
    }

    func testGetContentsOfDirectory() throws {
        var contents: [String] = [String]()
        createDirectory(atPath: "\(testDirectoryPath)/subpath")
        try fsManager.createSymbolicLink(atPath: "\(testDirectoryPath)/symbolic", ofObject: testDirectoryPath)
        contents = try fsManager.contentsOfDirectory(atPath: "\(testDirectoryPath)/symbolic")

        XCTAssertTrue(contents.contains("symbolic"))
        XCTAssertTrue(contents.contains("subpath"))
        deleteObject(atPath: "\(testDirectoryPath)/symbolic")
    }

    func testGetContentsOfNonExistsDirectory() {
        XCTAssertThrowsError(try fsManager.contentsOfDirectory(atPath: "/Foo/bar"))
    }

    func testCreateSymbolicLinkWithoutDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/symbolic")

        try fsManager.createSymbolicLink(atPath: "\(testDirectoryPath)/symbolic", ofObject: testFilePath)

        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/symbolic/file"))
        XCTAssertEqual(fsManager.typeOfObject(atPath: "\(testDirectoryPath)/symbolic/file"), .symbolicLink)
        deleteObject(atPath: "\(testDirectoryPath)/symbolic")
        deleteObject(atPath: testFilePath)
    }

    func testCreateSymbolicLinkWithDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)

        try fsManager.createSymbolicLink(atPath: "\(testDirectoryPath)/symlink", ofObject: testFilePath)

        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/symlink"))
        XCTAssertEqual(fsManager.typeOfObject(atPath: "\(testDirectoryPath)/symlink"), .symbolicLink)
        deleteObject(atPath: "\(testDirectoryPath)/symlink")
        deleteObject(atPath: testFilePath)
    }

    func testCreateSymbolicLinkOfNonExistsObject() {
        XCTAssertThrowsError(
            try fsManager.createSymbolicLink(atPath: "\(testDirectoryPath)/symlink", ofObject: "/Foo/bar")
        )
    }

    func testCreateHardLinkWithoutDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/hard")

        try fsManager.createHardLink(ofObject: testFilePath, toPath: "\(testDirectoryPath)/hard")

        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/hard/file"))
        XCTAssertEqual(fsManager.typeOfObject(atPath: "\(testDirectoryPath)/hard/file"), .regular)
        deleteObject(atPath: "\(testDirectoryPath)/hard")
        deleteObject(atPath: testFilePath)
    }

    func testCreateHardLinkWithDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)

        try fsManager.createHardLink(ofObject: testFilePath, toPath: "\(testDirectoryPath)/hardlink")

        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/hardlink"))
        XCTAssertEqual(fsManager.typeOfObject(atPath: "\(testDirectoryPath)/hardlink"), .regular)
        deleteObject(atPath: "\(testDirectoryPath)/hardlink")
        deleteObject(atPath: testFilePath)
    }

    func testCreateHardLinkOfNonExistsObject() {
        XCTAssertThrowsError(
            try fsManager.createHardLink(ofObject: "/Foo/bar", toPath: "\(testDirectoryPath)/hardlink")
        )
    }

    func testDeleteObject() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)
        XCTAssertTrue(fsManager.existsObject(atPath: testFilePath))

        try fsManager.deleteObject(atPath: testFilePath)

        XCTAssertFalse(fsManager.existsObject(atPath: testFilePath))
    }

    func testMoveObjectWithoutDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/move")
        XCTAssertTrue(fsManager.existsObject(atPath: testFilePath))

        try fsManager.moveObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/move")

        XCTAssertFalse(fsManager.existsObject(atPath: testFilePath))
        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/move/file"))
        deleteObject(atPath: "\(testDirectoryPath)/move")
    }

    func testMoveObjectWithDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/move")
        XCTAssertTrue(fsManager.existsObject(atPath: testFilePath))

        try fsManager.moveObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/move/movefile")

        XCTAssertFalse(fsManager.existsObject(atPath: testFilePath))
        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/move/movefile"))
        deleteObject(atPath: "\(testDirectoryPath)/move")
    }

    func testMoveNonExistsObject() {
        XCTAssertThrowsError(
            try fsManager.createSymbolicLink(atPath: "\(testDirectoryPath)/movefile", ofObject: "/Foo/bar")
        )
    }

    func testCopyObjectWithoutDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/copy")

        try fsManager.copyObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/copy")

        XCTAssertTrue(fsManager.existsObject(atPath: testFilePath))
        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/copy/file"))
        deleteObject(atPath: testFilePath)
        deleteObject(atPath: "\(testDirectoryPath)/copy")
    }

    func testCopyObjectWithDestinationObjectName() throws {
        fsManager.createFile(atPath: testFilePath, content: nil)

        try fsManager.copyObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/copyfile")

        XCTAssertTrue(fsManager.existsObject(atPath: testFilePath))
        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/copyfile"))
        deleteObject(atPath: testFilePath)
        deleteObject(atPath: "\(testDirectoryPath)/copyfile")
    }

    func testCopyNonExistsObject() {
        XCTAssertThrowsError(try fsManager.copyObject(atPath: "/Foo/bar", toPath: testDirectoryPath))
    }

    func testCreateDirectory() throws {
        try fsManager.createDirectory(atPath: "\(testDirectoryPath)/testcreatedirectory")

        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/testcreatedirectory"))
        deleteObject(atPath: "\(testDirectoryPath)/testcreatedirectory")
    }

    func testCreateDirectoryWhichIsAlreadyExists() {
        do {
            try fsManager.createDirectory(atPath: "\(testDirectoryPath)/testcreatedirectory")
        } catch let error as SomeError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }

        XCTAssertTrue(fsManager.existsObject(atPath: "\(testDirectoryPath)/testcreatedirectory"))

        XCTAssertThrowsError(try fsManager.createDirectory(atPath: "\(testDirectoryPath)/testcreatedirectory"))
        deleteObject(atPath: "\(testDirectoryPath)/testcreatedirectory")
    }

}
