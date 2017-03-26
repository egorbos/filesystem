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

import Foundation
import Error

/// The reasons due to which the error can be thrown by FileSystem modules.
public enum FSError: ErrorReasonProtocol {
    case objectDoesNotExist(path: String)
    case objectAlreadyExists(path: String)
    case createSymlinkFailed(from: String, to: String)
    case createHardlinkFailed(from: String, to: String)
    case createObjectFailed(path: String)
    case deleteObjectFailed(path: String)
    case moveObjectFailed(from: String, to: String)
    case copyObjectFailed(from: String, to: String)
    case getDirectoryContentsFailed(path: String)
    case getAttributesFailed(path: String)
    case setAttributesFailed(path: String)
    case openFileAtPathFailed(path: String)
    case fileIsNotOpen(fileDescriptor: Int32)
}

// MARK: - ErrorReason Descriptions
extension FSError {

    /// Returns a human-readable textual representation of the receiver.
    public var message: String {
        switch self {
        case let .objectDoesNotExist(path):
            return "Object does not exist at \(path)"
        case let .objectAlreadyExists(path):
            return "Object already exists at \(path)"
        case let .createSymlinkFailed(fromPath, toPath):
            return "Could not create symlink from \(fromPath) to \(toPath)"
        case let .createHardlinkFailed(fromPath, toPath):
            return "Could not create a hard link from \(fromPath) to \(toPath)"
        case let .createObjectFailed(path):
            return "Could not create object at \(path)"
        case let .deleteObjectFailed(path):
            return "Could not delete object at \(path)"
        case let .moveObjectFailed(fromPath, toPath):
            return "Could not move object at \(fromPath) to \(toPath)"
        case let .copyObjectFailed(fromPath, toPath):
            return "Could not copy object from \(fromPath) to \(toPath)"
        case let .getAttributesFailed(path):
            return "Could not get attributes for object at \(path)"
        case let .setAttributesFailed(path):
            return "Could not set attributes for object at \(path)"
        case let .getDirectoryContentsFailed(path):
            return "Could not get contents of directory at \(path)"
        case let .openFileAtPathFailed(path):
            return "Could not open file at \(path)"
        case let .fileIsNotOpen(fileDescriptor):
            return "File with descriptor: \(fileDescriptor), is not open"
        }
    }

}
