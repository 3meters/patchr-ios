//
//  Created by Jay Massena on 11/27/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit
import Foundation
import PhoneNumberKit

class FloatPhoneField: FloatTextField {
    
    let phoneNumberKit = PhoneNumberKit()
    let partialFormatter: PartialFormatter
    let nonNumericSet: NSCharacterSet = {
        var mutableSet = NSMutableCharacterSet.decimalDigit().inverted
        mutableSet.remove(charactersIn: "+＋")
        return mutableSet as NSCharacterSet
    }()
    
    /* Override region to set a custom region. Automatically uses the default region code. */
    public var defaultRegion = PhoneNumberKit.defaultRegionCode() {
        didSet {
            partialFormatter.defaultRegion = self.defaultRegion
        }
    }
    public var withPrefix: Bool = true {
        didSet {
            if withPrefix == false {
                self.keyboardType = .numberPad
            }
            else {
                self.keyboardType = .phonePad
            }
        }
    }
    public var currentRegion: String {
        get {
            return self.partialFormatter.currentRegion
        }
    }
    public var isValidNumber: Bool {
        get {
            let rawNumber = self.text ?? String()
            do {
                let _ = try self.phoneNumberKit.parse(rawNumber, withRegion: self.currentRegion)
                return true
            }
            catch {
                return false
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/

    override public init(frame:CGRect) {
        self.partialFormatter = PartialFormatter(phoneNumberKit: self.phoneNumberKit
            , defaultRegion: self.defaultRegion
            , withPrefix: self.withPrefix)
        super.init(frame: frame)
        initialize()
    }

    required public init(coder aDecoder: NSCoder) {
        self.partialFormatter = PartialFormatter(phoneNumberKit: self.phoneNumberKit
            , defaultRegion: self.defaultRegion
            , withPrefix: self.withPrefix)
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func initialize(){
        super.initialize()
        self.autocorrectionType = .no
        self.keyboardType = .phonePad
    }
    
    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    public override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let text = text else { return false }
        
        /* Allow delegate to intervene */
        if !super.textField(textField, shouldChangeCharactersIn: range, replacementString: string) {
            return false
        }
        
        let textAsNSString = text as NSString
        let changedRange = textAsNSString.substring(with: range) as NSString
        let modifiedTextField = textAsNSString.replacingCharacters(in: range, with: string)
        let formattedNationalNumber = self.partialFormatter.formatPartial(modifiedTextField as String)
        var selectedTextRange: NSRange?
        let nonNumericRange = (changedRange.rangeOfCharacter(from: self.nonNumericSet as CharacterSet).location != NSNotFound)
        
        if (range.length == 1 && string.isEmpty && nonNumericRange) {
            selectedTextRange = selectionRangeForNumberReplacement(textField: textField, formattedText: modifiedTextField)
            textField.text = modifiedTextField
        }
        else {
            selectedTextRange = selectionRangeForNumberReplacement(textField: textField, formattedText: formattedNationalNumber)
            textField.text = formattedNationalNumber
        }
        
        sendActions(for: .editingChanged)
        
        if let selectedTextRange = selectedTextRange, let selectionRangePosition = textField.position(from: self.beginningOfDocument, offset: selectedTextRange.location) {
            let selectionRange = textField.textRange(from: selectionRangePosition, to: selectionRangePosition)
            textField.selectedTextRange = selectionRange
        }
        
        return false
    }

    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    internal func extractCursorPosition() -> CursorPosition? {
        
        guard let text = text, let selectedTextRange = selectedTextRange else {
            return nil
        }
        
        var repetitionCountFromEnd = 0
        let textAsNSString = text as NSString
        let cursorEnd = offset(from: beginningOfDocument, to: selectedTextRange.end)
        
        /* Look for the next valid number after the cursor, when found return a CursorPosition struct */
        for i in cursorEnd ..< textAsNSString.length  {
            let cursorRange = NSMakeRange(i, 1)
            let candidateNumberAfterCursor: NSString = textAsNSString.substring(with: cursorRange) as NSString
            if (candidateNumberAfterCursor.rangeOfCharacter(from: nonNumericSet as CharacterSet).location == NSNotFound) {
                for j in cursorRange.location ..< textAsNSString.length  {
                    let candidateCharacter = textAsNSString.substring(with: NSMakeRange(j, 1))
                    if candidateCharacter == candidateNumberAfterCursor as String {
                        repetitionCountFromEnd += 1
                    }
                }
                return CursorPosition(numberAfterCursor: candidateNumberAfterCursor as String, repetitionCountFromEnd: repetitionCountFromEnd)
            }
        }
        
        return nil
    }
    
    // Finds position of previous cursor in new formatted text
    internal func selectionRangeForNumberReplacement(textField: UITextField, formattedText: String) -> NSRange? {
        
        guard let cursorPosition = extractCursorPosition() else {
            return nil
        }
        
        let textAsNSString = formattedText as NSString
        var countFromEnd = 0
        
        for i in stride(from: (textAsNSString.length - 1), through: 0, by: -1) {
            let candidateRange = NSMakeRange(i, 1)
            let candidateCharacter = textAsNSString.substring(with: candidateRange)
            if candidateCharacter == cursorPosition.numberAfterCursor {
                countFromEnd += 1
                if countFromEnd == cursorPosition.repetitionCountFromEnd {
                    return candidateRange
                }
            }
        }
        
        return nil
    }
    
    internal struct CursorPosition {
        /* To keep the cursor position, we find the character immediately after the cursor and
         count the number of times it repeats in the remaining string as this will remain
         constant in every kind of editing. */
        let numberAfterCursor: String
        let repetitionCountFromEnd: Int
    }
}
