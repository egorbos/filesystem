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

public extension String {
    
    public var lastPathComponent: String {
        let components = self.characters.split(separator: "/")
        let words = components.count - 1
        let tail = components.dropFirst(words).map(String.init)[0]
        return tail
    }
    
    public var deletingLastPathComponent: String {
        let components = self.characters.split(separator: "/")
        let head = components.dropLast(1).map(String.init).joined(separator: "/")
        return "/\(head)"
    }
    
    public var directoryPathForWrite: String {
        return self.hasSuffix("/") ? self : "\(self)/"
    }
    
}
