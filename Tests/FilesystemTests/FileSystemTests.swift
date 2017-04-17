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
import Foundation

@testable import Filesystem

class FileSystemTests: XCTestCase {

    let fileSystem = FileSystem()

    fileprivate let workPath = FileManager.default.currentDirectoryPath
    fileprivate var testDirectoryPath: String {
        return "\(workPath)/testdirectory"
    }
    fileprivate var testFilePath: String {
        return "\(testDirectoryPath)/file"
    }

    static var allTests : [(String, (FileSystemTests) -> () throws -> Void)] {
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
            try fileSystem.createDirectory(atPath: testDirectoryPath)
        } catch let error as FileSystemError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }

        XCTAssertTrue(fileSystem.existsObject(atPath: testDirectoryPath))
    }

    override func tearDown() {
        deleteObject(atPath: testDirectoryPath)
        super.tearDown()
    }

    // MARK: - Helpers

    fileprivate func deleteObject(atPath path: String) {
        do {
            try fileSystem.deleteObject(atPath: path)
        } catch let error as FileSystemError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }
    }

    fileprivate func createDirectory(atPath path: String) {
        do {
            try fileSystem.createDirectory(atPath: path)
        } catch let error as FileSystemError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }
    }

    // MARK: - Tests

    func testObjectExist() {
        XCTAssertFalse(fileSystem.existsObject(atPath: testFilePath))
        let content = "Content".data(using: .utf8)!
        XCTAssertTrue(fileSystem.createFile(atPath: testFilePath, content: content))


        XCTAssertTrue(fileSystem.existsObject(atPath: testFilePath))
        deleteObject(atPath: testFilePath)
    }

    func testGetObjectAttributes() throws {
        var attributes: [String : AnyHashable]?
        XCTAssertThrowsError(try fileSystem.attributesOfObject(atPath: testFilePath))
        fileSystem.createFile(atPath: testFilePath, content: nil)

        attributes = try fileSystem.attributesOfObject(atPath: testFilePath)

        XCTAssertNotNil(attributes)
        deleteObject(atPath: testFilePath)
    }

    func testGetAttributesOfNonExistsObject() {
        XCTAssertThrowsError(try fileSystem.attributesOfObject(atPath: "/Foo/bar"))
    }

    func testGetPermissionsForObject() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)

        XCTAssertTrue(fileSystem.isReadableObject(atPath: testFilePath))
        XCTAssertTrue(fileSystem.isWritableObject(atPath: testFilePath))
        XCTAssertFalse(fileSystem.isExecutableObject(atPath: testFilePath))
    }

    func testGetContentsOfDirectory() throws {
        var contents: [String] = [String]()
        createDirectory(atPath: "\(testDirectoryPath)/subpath")
        try fileSystem.createSymbolicLink(atPath: "\(testDirectoryPath)/symbolic", ofObject: testDirectoryPath)
        contents = try fileSystem.contentsOfDirectory(atPath: "\(testDirectoryPath)/symbolic")

        XCTAssertTrue(contents.contains("symbolic"))
        XCTAssertTrue(contents.contains("subpath"))
        deleteObject(atPath: "\(testDirectoryPath)/symbolic")
    }

    func testGetContentsOfNonExistsDirectory() {
        XCTAssertThrowsError(try fileSystem.contentsOfDirectory(atPath: "/Foo/bar"))
    }

    func testCreateSymbolicLinkWithoutDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/symbolic")

        try fileSystem.createSymbolicLink(atPath: "\(testDirectoryPath)/symbolic", ofObject: testFilePath)

        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/symbolic/file"))
        XCTAssertEqual(fileSystem.typeOfObject(atPath: "\(testDirectoryPath)/symbolic/file"), .symbolicLink)
        deleteObject(atPath: "\(testDirectoryPath)/symbolic")
        deleteObject(atPath: testFilePath)
    }

    func testCreateSymbolicLinkWithDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)

        try fileSystem.createSymbolicLink(atPath: "\(testDirectoryPath)/symlink", ofObject: testFilePath)

        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/symlink"))
        XCTAssertEqual(fileSystem.typeOfObject(atPath: "\(testDirectoryPath)/symlink"), .symbolicLink)
        deleteObject(atPath: "\(testDirectoryPath)/symlink")
        deleteObject(atPath: testFilePath)
    }

    func testCreateSymbolicLinkOfNonExistsObject() {
        XCTAssertThrowsError(
            try fileSystem.createSymbolicLink(atPath: "\(testDirectoryPath)/symlink", ofObject: "/Foo/bar")
        )
    }

    func testCreateHardLinkWithoutDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/hard")

        try fileSystem.createHardLink(ofObject: testFilePath, toPath: "\(testDirectoryPath)/hard")

        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/hard/file"))
        XCTAssertEqual(fileSystem.typeOfObject(atPath: "\(testDirectoryPath)/hard/file"), .regular)
        deleteObject(atPath: "\(testDirectoryPath)/hard")
        deleteObject(atPath: testFilePath)
    }

    func testCreateHardLinkWithDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)

        try fileSystem.createHardLink(ofObject: testFilePath, toPath: "\(testDirectoryPath)/hardlink")

        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/hardlink"))
        XCTAssertEqual(fileSystem.typeOfObject(atPath: "\(testDirectoryPath)/hardlink"), .regular)
        deleteObject(atPath: "\(testDirectoryPath)/hardlink")
        deleteObject(atPath: testFilePath)
    }

    func testCreateHardLinkOfNonExistsObject() {
        XCTAssertThrowsError(
            try fileSystem.createHardLink(ofObject: "/Foo/bar", toPath: "\(testDirectoryPath)/hardlink")
        )
    }

    func testDeleteObject() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)
        XCTAssertTrue(fileSystem.existsObject(atPath: testFilePath))

        try fileSystem.deleteObject(atPath: testFilePath)

        XCTAssertFalse(fileSystem.existsObject(atPath: testFilePath))
    }

    func testMoveObjectWithoutDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/move")
        XCTAssertTrue(fileSystem.existsObject(atPath: testFilePath))

        try fileSystem.moveObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/move")

        XCTAssertFalse(fileSystem.existsObject(atPath: testFilePath))
        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/move/file"))
        deleteObject(atPath: "\(testDirectoryPath)/move")
    }

    func testMoveObjectWithDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/move")
        XCTAssertTrue(fileSystem.existsObject(atPath: testFilePath))

        try fileSystem.moveObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/move/movefile")

        XCTAssertFalse(fileSystem.existsObject(atPath: testFilePath))
        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/move/movefile"))
        deleteObject(atPath: "\(testDirectoryPath)/move")
    }

    func testMoveNonExistsObject() {
        XCTAssertThrowsError(
            try fileSystem.createSymbolicLink(atPath: "\(testDirectoryPath)/movefile", ofObject: "/Foo/bar")
        )
    }

    func testCopyObjectWithoutDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)
        createDirectory(atPath: "\(testDirectoryPath)/copy")

        try fileSystem.copyObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/copy")

        XCTAssertTrue(fileSystem.existsObject(atPath: testFilePath))
        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/copy/file"))
        deleteObject(atPath: testFilePath)
        deleteObject(atPath: "\(testDirectoryPath)/copy")
    }

    func testCopyObjectWithDestinationObjectName() throws {
        fileSystem.createFile(atPath: testFilePath, content: nil)

        try fileSystem.copyObject(atPath: testFilePath, toPath: "\(testDirectoryPath)/copyfile")

        XCTAssertTrue(fileSystem.existsObject(atPath: testFilePath))
        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/copyfile"))
        deleteObject(atPath: testFilePath)
        deleteObject(atPath: "\(testDirectoryPath)/copyfile")
    }

    func testCopyNonExistsObject() {
        XCTAssertThrowsError(try fileSystem.copyObject(atPath: "/Foo/bar", toPath: testDirectoryPath))
    }

    func testCreateDirectory() throws {
        try fileSystem.createDirectory(atPath: "\(testDirectoryPath)/testcreatedirectory")

        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/testcreatedirectory"))
        deleteObject(atPath: "\(testDirectoryPath)/testcreatedirectory")
    }

    func testCreateDirectoryWhichIsAlreadyExists() {
        do {
            try fileSystem.createDirectory(atPath: "\(testDirectoryPath)/testcreatedirectory")
        } catch let error as FileSystemError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }

        XCTAssertTrue(fileSystem.existsObject(atPath: "\(testDirectoryPath)/testcreatedirectory"))

        XCTAssertThrowsError(try fileSystem.createDirectory(atPath: "\(testDirectoryPath)/testcreatedirectory"))
        deleteObject(atPath: "\(testDirectoryPath)/testcreatedirectory")
    }

}
