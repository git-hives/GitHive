//
//  string.swift
//  easy-git
//
//  Created by 1 on 3/4/23.
//

import Foundation

extension String {
    
    // 去除首尾空格
    func trimming() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func isAllDigits() -> Bool {
        let digitSet = CharacterSet.decimalDigits
        let nonDigitSet = digitSet.inverted
        return self.rangeOfCharacter(from: nonDigitSet) == nil
    }
}
