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
        0:MaterialColor.red.base,
        1:MaterialColor.pink.base,
        2:MaterialColor.purple.base,
        3:MaterialColor.deepPurple.base,
        4:MaterialColor.indigo.base,
        5:MaterialColor.lightBlue.base,
        6:MaterialColor.cyan.base,
        7:MaterialColor.teal.base,
        8:MaterialColor.green.base,
        9:MaterialColor.lightGreen.base,
        10:MaterialColor.lime.base,
        11:MaterialColor.amber.base,
        12:MaterialColor.orange.base,
        13:MaterialColor.deepOrange.base,
        14:MaterialColor.red.lighten1,
        15:MaterialColor.pink.lighten1,
        16:MaterialColor.purple.lighten1,
        17:MaterialColor.deepPurple.lighten1,
        18:MaterialColor.indigo.lighten1,
        19:MaterialColor.lightBlue.lighten1,
        20:MaterialColor.cyan.lighten1,
        21:MaterialColor.teal.lighten1,
        22:MaterialColor.green.lighten1,
        23:MaterialColor.lightGreen.lighten1,
        24:MaterialColor.lime.lighten1,
        25:MaterialColor.yellow.darken1,
        26:MaterialColor.amber.lighten1,
        27:MaterialColor.orange.lighten1,
        28:MaterialColor.deepOrange.lighten1
    ]
    
    static func randomColor(seed: Int) -> UIColor {
        let index = seed % 29
        return ColorArray.colors[index]!
    }
}
