import UIKit

class TextFieldView: UIView {

    var textField = AirTextField()
    var errorLabel = AirLabelDisplay()
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    required init(coder aDecoder: NSCoder) {
        /* Called when instantiated from XIB or Storyboard */
        super.init(coder: aDecoder)!
        initialize()
    }
    
    override init(frame: CGRect) {
        /* Called when instantiated from code */
        super.init(frame: frame)
        initialize()
    }

    /*--------------------------------------------------------------------------------------------
     * Events
     *--------------------------------------------------------------------------------------------*/
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let errorSize = self.errorLabel.sizeThatFits(CGSize(width: self.width(), height: CGFloat.greatestFiniteMagnitude))        
        self.textField.anchorTopCenter(withTopPadding: 0, width: self.width(), height: 48)
        self.errorLabel.alignUnder(self.textField, matchingCenterWithTopPadding: 0, width: self.width(), height: errorSize.height) // Extends below view if more than one line
    }
    
    /*--------------------------------------------------------------------------------------------
     * Methods
     *--------------------------------------------------------------------------------------------*/
    
    func setErrorText(text: String?) {
        self.errorLabel.text = text
        if text != nil {
            self.errorLabel.fadeIn()
        }
        else {
            self.errorLabel.fadeOut()
        }
        self.layoutSubviews()
    }
    
    func initialize() {
        
        self.errorLabel.textColor = Theme.colorTextValidationError
        self.errorLabel.alpha = 0.0
        self.errorLabel.numberOfLines = 0
        self.errorLabel.font = Theme.fontValidationError
        
        self.addSubview(self.textField)
        self.addSubview(self.errorLabel)
    }
}
