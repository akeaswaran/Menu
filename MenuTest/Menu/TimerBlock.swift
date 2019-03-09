//
//  TimerBlock.swift
//  Menu
//
//  Created by Alexander on 3/9/19.
//

import Foundation

internal class TimerBlock {
    let block: (Timer) -> Void
    
    init(block: @escaping (Timer) -> Void) {
        self.block = block
    }
    
    @objc func execute(_ timer: Timer) {
        block(timer)
    }
}

internal extension Timer {
    static func scheduledTimer(withTimeInterval timeInterval: TimeInterval, repeats: Bool, timerBlock block: @escaping (Timer) -> Void) -> Timer {
        let timer: Timer
        
        if #available(iOS 10, *) {
            timer = scheduledTimer(withTimeInterval: timeInterval, repeats: repeats, block: block)
        } else {
            let timerBlock = TimerBlock(block: block)
            timer = scheduledTimer(timeInterval: timeInterval, target: timerBlock, selector: #selector(TimerBlock.execute(_:)), userInfo: nil, repeats: repeats)
        }
        
        return timer
    }
}
