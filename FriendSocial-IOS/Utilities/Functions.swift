//
//  Functions.swift
//  FriendSocial-IOS
//
//  Created by Mitchell Zinck on 2024-09-10.
//

import Foundation

func unicodeToEmoji(_ unicodeString: String) -> String? {
    let hexString: String = unicodeString.replacingOccurrences(of: "U+", with: "")
    
    if let codePoint: UInt32 = UInt32(hexString, radix: 16), let scalar: Unicode.Scalar = Unicode.Scalar(codePoint) {
        return String(scalar)
    }
    
    return nil
}