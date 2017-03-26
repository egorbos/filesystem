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

#if os(macOS) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

import Foundation
import Error

public class FileHandler {

    // MARK: Properties, initialization, deinitialization

    /// Files open for processing.
    fileprivate var openFiles: [Int32: Int] = [:]

    init() {}

    /// Close all open files and delete all write queues
    deinit {
        for file in openFiles {
            close(file.key)
        }
        openFiles.removeAll()
    }

}

extension FileHandler {

    // MARK: File descriptor methods

    /// Returns the POSIX file descriptor for reading the file at the path,
    /// if the file exists.
    ///
    /// - Parameter path: Location of the file which needs to be read.
    ///
    /// - Throws: `FSError.openFileAtPathFailed`
    ///
    public func openFileForReading(atPath path: String) throws -> Int32 {
        let fd = open(path, O_RDONLY)
        guard fd > -1 else {
            throw SomeError(reason: FSError.openFileAtPathFailed(path: path))
        }
        let pathHash = path.hashValue
        openFiles[fd] = pathHash
        return fd
    }

    /// Returns the POSIX file descriptor for reading and writing the file at the path,
    /// if the file exists.
    ///
    /// - Parameter path: Location of the file which needs to be update.
    ///
    /// - Throws: `FSError.openFileAtPathFailed`
    ///
    public func openFileForUpdating(atPath path: String) throws -> Int32 {
        let fd = open(path, O_RDWR | O_CREAT)
        guard fd > -1 else {
            throw SomeError(reason: FSError.openFileAtPathFailed(path: path))
        }
        let pathHash = path.hashValue
        openFiles[fd] = pathHash
        return fd
    }

    /// Returns the POSIX file descriptor for writing to the file at the path,
    /// if the file exists.
    ///
    /// - Parameter path: Location of the file which needs to be write.
    ///
    /// - Throws: `FSError.openFileAtPathFailed`
    ///
    public func openFileForWriting(atPath path: String) throws -> Int32 {
        let fd = open(path, O_WRONLY | O_CREAT)
        guard fd > -1 else {
            throw SomeError(reason: FSError.openFileAtPathFailed(path: path))
        }
        let pathHash = path.hashValue
        openFiles[fd] = pathHash
        return fd
    }

    /// This method close the POSIX file descriptor.
    ///
    /// Attempts to read or write a closed file descriptor raise an exception.
    ///
    /// - Parameter fd: The POSIX descriptor of the file which needs to be closed.
    ///
    /// - Throws: `FSError.fileIsNotOpen`
    ///
    public func closeFile(descriptor fd: Int32) throws {
        guard let _ = openFiles.removeValue(forKey: fd) else {
            throw SomeError(reason: FSError.fileIsNotOpen(fileDescriptor: fd))
        }
    }

    /// Returns true if file is open, otherwise returns false.
    ///
    /// - Parameter fd: The POSIX descriptor of the file which needs to be cheked.
    ///
    public func isFileOpen(descriptor fd: Int32) -> Bool {
        return openFiles[fd] != nil ? true : false
    }

}

extension FileHandler {

    // MARK: File operations methods

    /// Returns the data obtained by reading available data up to the end
    /// of file or maximum number of bytes.
    ///
    /// - Parameter path: Location of the file which needs to be read.
    ///
    /// - Throws: 
    ///   - `FSError.openFileAtPathFailed`
    ///   - `FSError.fileIsNotOpen`
    ///
    public func readWholeFile(atPath path: String) throws -> Data {
        let descriptor = try openFileForReading(atPath: path)
        let data = try readWholeFile(atFileDescriptor: descriptor, shouldClose: true)
        return data
    }

    /// Returns the data obtained by reading available data up to the end
    /// of file or maximum number of bytes.
    ///
    /// - Parameters:
    ///   - fd:          The POSIX descriptor of the file which needs to be read.
    ///   - shouldClose: Whether to close the file after completion.
    ///                  Default value is `false`.
    ///
    /// - Throws: `FSError.fileIsNotOpen`
    ///
    public func readWholeFile(atFileDescriptor fd: Int32, shouldClose: Bool = false) throws -> Data {
        guard openFiles[fd] != nil else {
            throw SomeError(reason: FSError.fileIsNotOpen(fileDescriptor: fd))
        }
        var bytes: [UInt8] = []
        var count = 0
        
        let bufferSize = 8 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        defer {
            buffer.deinitialize()
            buffer.deallocate(capacity: bufferSize)
        }
        
        self.seek(toOffset: 0, descriptor: fd)
        
        repeat {
            count = read(fd, buffer, bufferSize)
            bytes.append(contentsOf: Array(UnsafeBufferPointer(start: buffer, count: count)))
        } while count > 0
        
        let data = Data(bytes: bytes)
        if shouldClose {
            try? self.closeFile(descriptor: fd)
        }
        return data
    }

    /// Returns the data obtained by reading length bytes starting at the specified file pointer.
    ///
    /// - Parameters:
    ///   - path:  Location of the file which needs to be read.
    ///   - start: The starting file pointer (byte), from where it is necessary to begin reading.
    ///   - end:   Ending file pointer (byte), where it is necessary to finish.
    ///
    /// - Throws: 
    ///   - `FSError.openFileAtPathFailed`
    ///   - `FSError.fileIsNotOpen`
    ///
    public func readBytesOfFile(atPath path: String, start: UInt64, end: UInt64) throws -> Data {
        let descriptor = try openFileForReading(atPath: path)
        let data = try readBytesOfFile(atFileDescriptor: descriptor, start: start, end: end, shouldClose: true)
        return data
    }

    /// Returns the data obtained by reading length bytes beginning at the specified file pointer.
    ///
    /// - Parameters:
    ///   - fd:          The POSIX descriptor of the file which needs to be read.
    ///   - start:       The starting file pointer (byte), from where it is necessary to begin reading.
    ///   - end:         Ending file pointer (byte), where it is necessary to finish.
    ///   - shouldClose: Whether to close the file after completion. Default value is `false`.
    ///
    /// - Throws: `FSError.fileIsNotOpen`
    ///
    public func readBytesOfFile(atFileDescriptor fd: Int32, start: UInt64,
                         end: UInt64, shouldClose: Bool = false) throws -> Data {
        guard openFiles[fd] != nil else {
            throw SomeError(reason: FSError.fileIsNotOpen(fileDescriptor: fd))
        }
        var wouldRead = Int(end - start)
        var bytes: [UInt8] = []
        var count = 0
        
        var bufferSize = 8 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        
        defer {
            buffer.deinitialize()
            buffer.deallocate(capacity: bufferSize)
        }
        
        self.seek(toOffset: start, descriptor: fd)
        
        repeat {
            if bufferSize > wouldRead {
                bufferSize = wouldRead
            }
            count = read(fd, buffer, bufferSize)
            bytes.append(contentsOf: Array(UnsafeBufferPointer(start: buffer, count: count)))
            wouldRead -= count
        } while wouldRead > 0
        
        let data = Data(bytes: bytes)
        if shouldClose {
            try? self.closeFile(descriptor: fd)
        }
        return data
    }

    /// Writes the specified data to the file, beginning at the specified file pointer.
    /// If the write operation is successful, return the actual number of bytes write in the file.
    ///
    ///
    /// - Parameters:
    ///   - path:    Location of the file which needs to be write.
    ///   - offset:  The starting file pointer (byte), from where it is necessary to begin writing.
    ///   - content: Contents which need to be written down.
    ///
    /// - Throws: 
    ///   - `FSError.openFileAtPathFailed`
    ///   - `FSError.fileIsNotOpen`
    ///
    /// - Note: This method rewrites existing data of the file.
    ///
    public func writeContentInFile(atPath path: String, offset: UInt64, content: Data) throws -> UInt64 {
        let descriptor = try openFileForWriting(atPath: path)
        let count = try writeContentInFile(atFileDescriptor: descriptor, offset: offset,
                                           content: content, shouldClose: true)
        return count
    }

    /// Writes the specified data to the file, beginning at the specified file pointer.
    /// If the write operation is successful, return the actual number of bytes write in the file.
    ///
    /// - Parameters:
    ///   - fd:          The POSIX descriptor of the file which needs to be read.
    ///   - offset:      The starting file pointer (byte), from where it is necessary to begin writing.
    ///   - content:     Contents which need to be written down.
    ///   - shouldClose: Whether to close the file after completion. Default value is `false`.
    ///
    /// - Throws: `FSError.fileIsNotOpen`
    ///
    /// - Note: This method rewrites existing data of the file.
    ///
    @discardableResult
    public func writeContentInFile(atFileDescriptor fd: Int32,
                            offset: UInt64, content: Data,
                            shouldClose: Bool = false) throws -> UInt64 {
        guard let _ = openFiles[fd] else {
            throw SomeError(reason: FSError.fileIsNotOpen(fileDescriptor: fd))
        }
        
        self.seek(toOffset: offset, descriptor: fd)
        let count = self.writeData(content, to: fd)
        
        if shouldClose {
            try? self.closeFile(descriptor: fd)
        }
        
        return count
    }

    /// Writes the specified data to the end of file.
    /// If the write operation is successful, return the actual number of bytes write in the file.
    ///
    /// - Parameters:
    ///   - path:    Location of the file which needs to be write.
    ///   - content: Contents which need to be written down.
    ///
    /// - Throws: 
    ///   - `FSError.openFileAtPathFailed`
    ///   - `FSError.fileIsNotOpen`
    ///
    @discardableResult
    public func writeContentToEndOfFile(atPath path: String, content: Data) throws -> UInt64 {
        let descriptor = try openFileForWriting(atPath: path)
        let count = try writeContentToEndOfFile(atFileDescriptor: descriptor,
                                                content: content, shouldClose: true)
        return count
    }

    /// Writes the specified data to the end of file.
    /// If the write operation is successful, return the actual number of bytes write in the file.
    ///
    /// - Parameters: 
    ///   - fd:          The POSIX descriptor of the file which needs to be read.
    ///   - content:     Contents which need to be written down.
    ///   - shouldClose: Whether to close the file after completion.
    ///                  Default value is `false`.
    ///
    /// - Throws: `FSError.fileIsNotOpen`
    ///
    @discardableResult
    public func writeContentToEndOfFile(atFileDescriptor fd: Int32,
                                        content: Data, shouldClose: Bool = false) throws -> UInt64 {
        guard let _ = openFiles[fd] else {
            throw SomeError(reason: FSError.fileIsNotOpen(fileDescriptor: fd))
        }
        
        self.seekToEndOfFile(descriptor: fd)
        let count = self.writeData(content, to: fd)
        
        if shouldClose {
            try? self.closeFile(descriptor: fd)
        }
        
        return count
    }

    /// Truncates the file to a specified offset within the file and puts the file pointer at that position.
    ///
    /// - Parameters:
    ///   - path:        Location of the file which needs to be truncate.
    ///   - offset:      Ending file pointer (byte), where it is necessary to finish.
    ///
    /// - Throws: 
    ///   - `FSError.openFileAtPathFailed`
    ///   - `FSError.fileIsNotOpen`
    ///
    public func truncateFile(atPath path: String, toOffset offset: UInt64) throws {
        let descriptor = try openFileForWriting(atPath: path)
        try truncateFile(atFileDescriptor: descriptor, toOffset: offset, shouldClose: true)
    }

    /// Truncates the file to a specified offset within the file and puts the file pointer at that position.
    ///
    /// - Parameters:
    ///   - fd:          The POSIX descriptor of the file which needs to be truncate.
    ///   - offset:      Ending file pointer (byte), where it is necessary to finish truncating.
    ///   - shouldClose: Whether to close the file after completion. Default value is `false`.
    ///
    /// - Throws: `FSError.fileIsNotOpen`
    ///
    public func truncateFile(atFileDescriptor fd: Int32,
                             toOffset offset: UInt64,
                             shouldClose: Bool = false) throws {
        guard let _ = openFiles[fd] else {
            throw SomeError(reason: FSError.fileIsNotOpen(fileDescriptor: fd))
        }
        
        #if os(macOS) || os(iOS)
            ftruncate(fd, Int64(offset))
        #elseif os(Linux) || CYGWIN
            ftruncate(fd, Int(offset))
        #endif
        
        if shouldClose {
            try? self.closeFile(descriptor: fd)
        }
    }

}

extension FileHandler {

    // MARK: Private methods

    fileprivate func seekToEndOfFile(descriptor fd: Int32) {
        lseek(fd, 0, SEEK_END)
    }

    fileprivate func seek(toOffset offset: UInt64, descriptor fd: Int32) {
        #if os(macOS) || os(iOS)
            lseek(fd, Int64(offset), SEEK_SET)
        #elseif os(Linux) || CYGWIN
            lseek(fd, Int(offset), SEEK_SET)
        #endif
    }

    fileprivate func writeData(_ data: Data, to descriptor: Int32) -> UInt64 {
        var wouldWrite = data.count
        var count = 0

        var bufferSize = 8 * 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        defer {
            buffer.deinitialize()
            buffer.deallocate(capacity: bufferSize)
        }

        repeat {
            if bufferSize > wouldWrite {
                bufferSize = wouldWrite
            }
            let range = Range<Data.Index>(count...(count + (bufferSize - 1)))
            data.copyBytes(to: buffer, from: range)
            let done = write(descriptor, buffer, bufferSize)
            count += done
            wouldWrite -= done
        } while wouldWrite > 0
        
        return UInt64(count)
    }

}
