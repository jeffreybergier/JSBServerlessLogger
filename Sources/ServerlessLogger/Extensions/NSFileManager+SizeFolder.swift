//
//  NSFileManager+SizeFolder.swift
//  ServerlessLogger
//
//  Created by Jeffrey Bergier on 2020/09/27.
//

import Foundation

extension Foundation.FileManager {
    /// Iterates through every file and subfolder to get the total bytes
    /// returns: Size in bytes
    internal func size(folder: URL) throws -> Int {
        let properties: Set<URLResourceKey> = [.totalFileAllocatedSizeKey]
        guard let enumerator = self.enumerator(at: folder, includingPropertiesForKeys: Array(properties)) else {
            throw NSError() // provided URL was probably a file or doesn't exist
        }
        var size: Int = 0
        var next: URL?
        let progress = {
            next = enumerator.nextObject() as! URL?
        }
        progress()
        guard next != nil else {
            throw NSError() // provided URL was probably a file or doesn't exist
        }
        while next != nil {
            defer { progress() }
            let resources = try next!.resourceValues(forKeys: properties)
            let totalFileAllocatedSize = resources.totalFileAllocatedSize ?? 0
            size += totalFileAllocatedSize
        }
        return size
    }
}
