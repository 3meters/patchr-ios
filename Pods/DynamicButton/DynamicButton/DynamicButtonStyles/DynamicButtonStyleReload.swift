/*
 * DynamicButton
 *
 * Copyright 2015-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

/// Reload symbol style: ↻
final public class DynamicButtonStyleReload: DynamicButtonStyle {
  convenience required public init(center: CGPoint, size: CGFloat, offset: CGPoint, lineWidth: CGFloat) {
    let sixthSize = size / 6
    let fifthPi   = CGFloat(M_PI / 5.5)

    let endAngle = CGFloat((3 * M_PI) / 2) - fifthPi
    let endPoint = PathHelper.pointFromCenter(center, radius: size / 2 - lineWidth, angle: endAngle)

    let curveBezierPath = UIBezierPath(arcCenter: center, radius: size / 2 - lineWidth, startAngle: -fifthPi, endAngle: endAngle, clockwise: true)
    let path            = curveBezierPath.CGPath

    let path1 = PathHelper.lineFrom(endPoint, to: PathHelper.pointFromCenter(endPoint, radius: sixthSize, angle: CGFloat(M_PI)))
    let path2 = PathHelper.lineFrom(endPoint, to: PathHelper.pointFromCenter(endPoint, radius: sixthSize, angle: CGFloat(M_PI / 2)))

    self.init(path1: path1, path2: path2, path3: path, path4: path)
  }

  // MARK: - Conforming the CustomStringConvertible Protocol

  /// A textual representation of "Reload" style.
  public override var description: String {
    return "Reload"
  }
}