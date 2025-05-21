//
//  Shared.swift
//  VRC RoboScout
//
//  Created by William Castro on 7/29/24.
//

import Foundation

func displayRoundedTenths(number: Double) -> String {
    return String(format: "%.1f", round(number * 10.0) / 10.0)
}

func displayRounded(number: Double) -> String {
    return String(format: "%.0f", round(number))
}

extension String: @retroactive Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")
    
    public func convertedToSlug() -> String? {
        if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) {
            let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
            let result = urlComponents.filter { $0 != "" }.joined(separator: "-")
            
            if result.count > 0 {
                return result
            }
        }
        
        return nil
    }
}
