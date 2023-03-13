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


// 分割字符串
// 如下字符串："origin/test/test"  分割后：["origin", "test/test"]
func splitString(_ str: String, delimiter: Character) -> [String] {
    if let index = str.firstIndex(of: delimiter) {
        let firstPart = String(str.prefix(upTo: index))
        let secondPart = String(str.suffix(from: index).dropFirst())
        return [firstPart, secondPart]
    }
    return [str]
}
