//
//  FileManager+Documents.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/17/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import Foundation

extension FileManager {
    
    public static func documentURL() -> URL? {
        return self.documentURL(childPath: nil)
    }
    
    // recuperer le chemin absolue du doc + rajout childpath ex: /data.db
    public static func documentURL(childPath: String?) -> URL? {
        // renvoie chemin absolue du document
        if let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if let path = childPath {
                return documentURL.appendingPathComponent(path)
            }
            return documentURL
        }
        return nil
    }
}
