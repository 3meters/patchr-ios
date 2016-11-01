//
//  ColorArray.swift
//  Patchr
//
//  Created by Jay Massena on 10/22/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

struct ColorArray {
    
    static let colors: [Int:UIColor] = [
        0:Color.red.base,
        1:Color.pink.base,
        2:Color.purple.base,
        3:Color.deepPurple.base,
        4:Color.indigo.base,
        5:Color.lightBlue.base,
        6:Color.cyan.base,
        7:Color.teal.base,
        8:Color.green.base,
        9:Color.lightGreen.base,
        10:Color.lime.base,
        11:Color.amber.base,
        12:Color.orange.base,
        13:Color.deepOrange.base,
        14:Color.red.lighten1,
        15:Color.pink.lighten1,
        16:Color.purple.lighten1,
        17:Color.deepPurple.lighten1,
        18:Color.indigo.lighten1,
        19:Color.lightBlue.lighten1,
        20:Color.cyan.lighten1,
        21:Color.teal.lighten1,
        22:Color.green.lighten1,
        23:Color.lightGreen.lighten1,
        24:Color.lime.lighten1,
        25:Color.yellow.lighten1,
        26:Color.amber.lighten1,
        27:Color.orange.lighten1,
        28:Color.deepOrange.lighten1
    ]
    
    static func randomColor(seed: Int) -> UIColor {
        let index = seed % 29
        return ColorArray.colors[index]!
    }
}
