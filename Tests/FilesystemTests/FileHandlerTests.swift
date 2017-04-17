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

class FileHandlerTests: XCTestCase {

    let fsManager = FileSystem()
    let fileHandler = FileHandler()

    static var allTests : [(String, (FileHandlerTests) -> () throws -> Void)] {
        return [
            ("testOpenFileForReading", testOpenFileForReading),
            ("testOpenFileForUpdating", testOpenFileForUpdating),
            ("testOpenFileForWriting", testOpenFileForWriting),
            ("testIsFileOpen", testIsFileOpen),
            ("testReadWholeFileAtPath", testReadWholeFileAtPath),
            ("testReadWholeFileAtFileDescriptor", testReadWholeFileAtFileDescriptor),
            ("testReadBytesOfFileAtPath", testReadBytesOfFileAtPath),
            ("testReadBytesOfFileAtFileDescriptor", testReadBytesOfFileAtFileDescriptor),
            ("testWriteContentInFileAtPath", testWriteContentInFileAtPath),
            ("testWriteContentInFileAtFileDescriptor", testWriteContentInFileAtFileDescriptor),
            ("testWriteContentInFileToEOFAtPath", testWriteContentInFileToEOFAtPath),
            ("testWriteContentInFileToEOFAtFileDescriptor", testWriteContentInFileToEOFAtFileDescriptor),
            ("testTruncateFileAtPath", testTruncateFileAtPath),
            ("testTruncateFileAtFileDescriptor", testTruncateFileAtFileDescriptor)
        ]
    }

    // MARK: - Helpers

    func createTestFile(atPath path: String) {
        let content = "abcdefghijklmnopqrstuvwxyz".data(using: .utf8)!
        fsManager.createFile(atPath: path, content: content)
    }

    func generateFileName() -> String {
        return "\(fsManager.workPath)/\(UUID().uuidString)"
    }
    
    func deleteTestFile(atPath path: String) {
        do {
            try fsManager.deleteObject(atPath: path)
        } catch let error as FileSystemError  {
            XCTFail(error.description)
        } catch {
            XCTFail("Unhandled error")
        }
    }

    // MARK: - Tests

    func testOpenFileForReading() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let descriptor = try fileHandler.openFileForReading(atPath: testfilePath)
        XCTAssertNotNil(descriptor)
        try fileHandler.closeFile(descriptor: descriptor)

        deleteTestFile(atPath: testfilePath)
    }

    func testOpenFileForUpdating() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let descriptor = try fileHandler.openFileForUpdating(atPath: testfilePath)
        XCTAssertNotNil(descriptor)
        try fileHandler.closeFile(descriptor: descriptor)

        deleteTestFile(atPath: testfilePath)
    }

    func testOpenFileForWriting() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let descriptor = try fileHandler.openFileForWriting(atPath: testfilePath)
        XCTAssertNotNil(descriptor)
        try fileHandler.closeFile(descriptor: descriptor)

        deleteTestFile(atPath: testfilePath)
    }

    func testIsFileOpen() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let descriptor = try fileHandler.openFileForWriting(atPath: testfilePath)
        XCTAssertTrue(fileHandler.isFileOpen(descriptor: descriptor))
        try fileHandler.closeFile(descriptor: descriptor)
        XCTAssertFalse(fileHandler.isFileOpen(descriptor: descriptor))

        deleteTestFile(atPath: testfilePath)
    }

    func testReadWholeFileAtPath() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))
        
        let data = try fileHandler.readWholeFile(atPath: testfilePath)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "abcdefghijklmnopqrstuvwxyz")
        deleteTestFile(atPath: testfilePath)
    }

    func testReadWholeFileAtFileDescriptor() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let descriptor = try fileHandler.openFileForReading(atPath: testfilePath)
        let data = try fileHandler.readWholeFile(atFileDescriptor: descriptor)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "abcdefghijklmnopqrstuvwxyz")
        deleteTestFile(atPath: testfilePath)
    }

    func testReadBytesOfFileAtPath() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let data = try fileHandler.readBytesOfFile(atPath: testfilePath, start: 3, end: 6)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "def")
        deleteTestFile(atPath: testfilePath)
    }

    func testReadBytesOfFileAtFileDescriptor() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let descriptor = try fileHandler.openFileForReading(atPath: testfilePath)
        let data = try fileHandler.readBytesOfFile(atFileDescriptor: descriptor, start: 6, end: 9)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "ghi")
        deleteTestFile(atPath: testfilePath)
    }

    func testWriteContentInFileAtPath() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let recordData: Data = "mlkjihgfedcba".data(using: .utf8)!
        let count = try fileHandler.writeContentInFile(atPath: testfilePath, offset: 13, content: recordData)
        let data = try fileHandler.readWholeFile(atPath: testfilePath)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "abcdefghijklmmlkjihgfedcba")
        XCTAssertEqual(recordData.count, Int(count))
        deleteTestFile(atPath: testfilePath)
    }

    func testWriteContentInFileAtFileDescriptor() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let writeDescriptor = try fileHandler.openFileForWriting(atPath: testfilePath)
        let recordData = "zyxwvutsrqpon".data(using: .utf8)!
        let count = try fileHandler.writeContentInFile(atFileDescriptor: writeDescriptor, offset: 0, content: recordData)
        try fileHandler.closeFile(descriptor: writeDescriptor)
        
        let readDescriptor = try self.fileHandler.openFileForReading(atPath: testfilePath)
        let data = try fileHandler.readWholeFile(atFileDescriptor: readDescriptor)
        let content = String(data: data, encoding: .utf8)!
        try fileHandler.closeFile(descriptor: readDescriptor)

        XCTAssertEqual(content, "zyxwvutsrqponnopqrstuvwxyz")
        XCTAssertEqual(recordData.count, Int(count))
        deleteTestFile(atPath: testfilePath)
    }

    func testWriteContentInFileToEOFAtPath() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let recordData = "1234567890".data(using: .utf8)!
        let count = try fileHandler.writeContentToEndOfFile(atPath: testfilePath, content: recordData)
        
        let data = try self.fileHandler.readWholeFile(atPath: testfilePath)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "abcdefghijklmnopqrstuvwxyz1234567890")
        XCTAssertEqual(recordData.count, Int(count))
        deleteTestFile(atPath: testfilePath)
    }

    func testWriteContentInFileToEOFAtFileDescriptor() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let recordData = "0987654321".data(using: .utf8)!
        let writeDescriptor = try fileHandler.openFileForWriting(atPath: testfilePath)
        let count = try fileHandler.writeContentToEndOfFile(atFileDescriptor: writeDescriptor, content: recordData)
        try fileHandler.closeFile(descriptor: writeDescriptor)
        
        let readDescriptor = try self.fileHandler.openFileForReading(atPath: testfilePath)
        let data = try fileHandler.readWholeFile(atFileDescriptor: readDescriptor)
        let content = String(data: data, encoding: .utf8)!
        try fileHandler.closeFile(descriptor: readDescriptor)

        XCTAssertEqual(content, "abcdefghijklmnopqrstuvwxyz0987654321")
        XCTAssertEqual(recordData.count, Int(count))
        deleteTestFile(atPath: testfilePath)
    }

    func testTruncateFileAtPath() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        try fileHandler.truncateFile(atPath: testfilePath, toOffset: 0)

        let data = try self.fileHandler.readWholeFile(atPath: testfilePath)
        let content = String(data: data, encoding: .utf8)!

        XCTAssertEqual(content, "")
        deleteTestFile(atPath: testfilePath)
    }

    func testTruncateFileAtFileDescriptor() throws {
        let testfilePath = generateFileName()
        createTestFile(atPath: testfilePath)
        XCTAssertTrue(fsManager.existsObject(atPath: testfilePath))

        let writeDescriptor = try fileHandler.openFileForWriting(atPath: testfilePath)
        try fileHandler.truncateFile(atFileDescriptor: writeDescriptor, toOffset: 10)
        try fileHandler.closeFile(descriptor: writeDescriptor)
        
        let readDescriptor = try self.fileHandler.openFileForReading(atPath: testfilePath)
        let data = try fileHandler.readWholeFile(atFileDescriptor: readDescriptor)
        let content = String(data: data, encoding: .utf8)!
        try fileHandler.closeFile(descriptor: readDescriptor)

        XCTAssertEqual(content, "abcdefghij")
        deleteTestFile(atPath: testfilePath)
    }

}
