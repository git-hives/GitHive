//
//  date.swift
//  easy-git
//
//  Created by 1 on 3/10/23.
//

import Foundation

// 日期格式化
func formatDateString(dateString: String) -> String? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss yyyy Z"
    if let date = dateFormatter.date(from: dateString) {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.string(from: date)
    }
    return nil
}


// 获取时间戳，单位毫秒
func getCurrentTimeInMilliseconds() -> Int64 {
    let timeInterval = Date().timeIntervalSince1970
    let millisecond = Int64(timeInterval * 1000)
    return millisecond
}
