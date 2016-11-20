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
        0: MaterialColor.red.base,
        1: MaterialColor.pink.base,
        2: MaterialColor.purple.base,
        3: MaterialColor.deepPurple.base,
        4: MaterialColor.indigo.base,
        5: MaterialColor.lightBlue.base,
        6: MaterialColor.cyan.base,
        7: MaterialColor.green.base,
        8: MaterialColor.lightGreen.base,
        9: MaterialColor.lime.base,
        10: MaterialColor.amber.base,
        11: MaterialColor.orange.base,
        12: MaterialColor.deepOrange.base,
        13: MaterialColor.red.lighten1,
        14: MaterialColor.pink.lighten1,
        15: MaterialColor.purple.lighten1,
        16: MaterialColor.deepPurple.lighten1,
        17: MaterialColor.indigo.lighten1,
        18: MaterialColor.lightBlue.lighten1,
        19: MaterialColor.cyan.lighten1,
        20: MaterialColor.green.lighten1,
        21: MaterialColor.lightGreen.lighten1,
        22: MaterialColor.lime.lighten1,
        23: MaterialColor.yellow.darken1,
        24: MaterialColor.amber.lighten1,
        25: MaterialColor.orange.lighten1,
        26: MaterialColor.deepOrange.lighten1
    ]
    
    static func randomColor(seed: Int) -> UIColor {
        let index = seed % 27
        return ColorArray.colors[index]!
    }
}
