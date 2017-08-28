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
        7: MaterialColor.lightGreen.base,
        8: MaterialColor.lime.base,
        9: MaterialColor.amber.base,
        10: MaterialColor.orange.base,
        11: MaterialColor.deepOrange.base,
        
        12: MaterialColor.red.lighten1,
        13: MaterialColor.pink.lighten1,
        14: MaterialColor.purple.lighten1,
        15: MaterialColor.deepPurple.lighten1,
        16: MaterialColor.indigo.lighten1,
        17: MaterialColor.lightBlue.lighten1,
        18: MaterialColor.cyan.lighten1,
        19: MaterialColor.lightGreen.lighten1,
        20: MaterialColor.lime.lighten1,
        21: MaterialColor.yellow.darken1,
        22: MaterialColor.amber.lighten1,
        23: MaterialColor.orange.lighten1,
        24: MaterialColor.deepOrange.lighten1
    ]
    
    static func randomColor(seed: Int) -> UIColor {
        let index = seed % 25
        return ColorArray.colors[index]!
    }
}
