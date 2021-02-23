//
//  Extensions.swift
//  Wallet
//
//  Created by Weisu Yin on 10/6/19.
//  Copyright © 2019 UCDavis. All rights reserved.
//

import UIKit

protocol OTPTextFieldDelegate : UITextFieldDelegate {
    func didPressBackspace(_ textField: OTPTextField)
    func textFieldDidBeginEditing(_ textField: UITextField)
    func textFieldDidChangeSelection(_ textField: UITextField)
}

class OTPTextField: UITextField {
    var id = -1
    var nextField: OTPTextField?
    var prevField: OTPTextField?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        placeholder?.removeAll()
        isUserInteractionEnabled = false
    }
    
    override func deleteBackward() {
        if let otpDelegate = self.delegate as? OTPTextFieldDelegate {
            otpDelegate.didPressBackspace(self)
        }
        // super.deleteBackward()
    }
}

class OTPView: UIStackView, OTPTextFieldDelegate {
    
    private var otpTextFields: [OTPTextField?] = []
    private var curTextField: OTPTextField?
    private var lastEditableTextField: OTPTextField?
    private var isBusy: Bool = false
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        otpTextFields = arrangedSubviews.compactMap( { $0 as? OTPTextField } )
        
        curTextField = otpTextFields[0]
        lastEditableTextField = otpTextFields[0]
        
        curTextField?.isUserInteractionEnabled = true
        curTextField?.becomeFirstResponder()
        
        for (textField, id) in zip (otpTextFields, 0...otpTextFields.count - 1) {
            textField?.delegate = self
            textField?.id = id
            
            // Set next pointer to following text field
            // Final text field will have next point to itself
            textField?.nextField = id == otpTextFields.count - 1 ? textField : otpTextFields[id + 1]
            
            // Set prev pointer to previous text field
            // First text field will have prev point to itself
            textField?.prevField = id == 0 ? textField : otpTextFields[id - 1]
        }
    }
    
    /// Returns contents of all OTPTextFields as a single string
    private func getAllText() -> String {
        let code = otpTextFields.reduce("", { (text, field) -> String in
            text + (field?.text ?? "")
        })
        return code
    }
    
    /// Sets contents of all OTPTextFields to up to the first six characters of @str
    private func setAllText(_ str: String) {
        clearText()
        for (textField, char) in zip (otpTextFields, str) {
            textField?.text = "\(char)"
        }
    }
    
    /// Runs when multiple characters are in one text field
    /// Redistributes characters into one per text fieldt
    private func handleMultipleCharacters() {
        isBusy = true
        
        let numDigits = (curTextField?.text?.count ?? 0)
        if (numDigits < 2) {
            assertionFailure("no extra digits")
            return
        }
        
        guard let curTextFieldID = curTextField?.id else {
            assertionFailure("curTextField doesn't exist")
            return
        }
        guard let lastEditableTextFieldID = lastEditableTextField?.id else {
            assertionFailure("lastEditableTextField doesn't exist")
            return
        }
        
        // Set new curTextField
        let newCurTextFieldIndex = min(curTextFieldID + numDigits - 1, otpTextFields.count - 1)
        curTextField = otpTextFields[newCurTextFieldIndex]
        
        // Set new lastEditableTextField
        let newLastEditableTextFieldIndex = min(lastEditableTextFieldID + numDigits - 1, otpTextFields.count - 1)
        lastEditableTextField = otpTextFields[newLastEditableTextFieldIndex]
        
        // Make sure all necessary text fields are enabled
        for textField in otpTextFields[0...newLastEditableTextFieldIndex] {
            textField?.isUserInteractionEnabled = true
        }
        curTextField?.becomeFirstResponder()
        
        let str = getAllText()
        setAllText(str)
        
        isBusy = false
    }
    
    /// Clears all text fields
    func clearText() {
        otpTextFields.forEach({
            $0?.text?.removeAll()
        })
    }
    
    /// Clears all text fields and sets the first text field as first responder
    func resetAll() {
        curTextField = otpTextFields[0]
        lastEditableTextField = otpTextFields[0]
        otpTextFields.forEach({
            $0?.text?.removeAll()
            $0?.isUserInteractionEnabled = false
        })
        curTextField?.isUserInteractionEnabled = true
        curTextField?.becomeFirstResponder()
    }
    
    /// Moves cursor from one OTPTextField to the next, disabling the current one and enableing the next.
    /// Returns code if complete, otherwise returns Optional.none
    func moveCursor() -> String? {
        // So that this function does nothing while internal methods are editing the text field
        if isBusy {
            return Optional.none
        }
        
        var code: String? = Optional.none
        var multipleCharacters = false
        
        // print(getAllText())
        
        if curTextField?.text?.count ?? 0 > 1 {
            // More than one character was added at once
            handleMultipleCharacters()
            multipleCharacters = true
        }
        
        let lastTextFieldText = otpTextFields[otpTextFields.count - 1]?.text ?? ""
        if !lastTextFieldText.isEmpty {
            // Text fields are full
            code = getAllText()
        }
        else if !multipleCharacters {
            lastEditableTextField = lastEditableTextField?.nextField
            curTextField = curTextField?.nextField
            curTextField?.isUserInteractionEnabled = true
            curTextField?.becomeFirstResponder()
        }
        
        return code
    }
    
    func didPressBackspace(_ textField: OTPTextField) {
        isBusy = true
        
        if (lastEditableTextField?.id != 0 && !(lastEditableTextField?.id == 5 && lastEditableTextField?.text ?? "" != "")) {
            lastEditableTextField?.isUserInteractionEnabled = false
            lastEditableTextField = lastEditableTextField?.prevField
        }
        
        if (textField.text == "") {
            textField.prevField?.text?.removeAll()
        }
        else {
            textField.text?.removeAll()
        }
        
        curTextField = curTextField?.prevField
        
        let str = getAllText()
        setAllText(str)
        
        curTextField?.becomeFirstResponder()
        
        isBusy = false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isBusy = true
        
        guard let otpTextField = textField as? OTPTextField else {
            assertionFailure("UITextField not cast as OTPTextField")
            return
        }
        curTextField = otpTextField
        textField.updateFloatingCursor(at: .zero)
        
        isBusy = false
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // Always have cursor be at the end of a text field
        let endPosition = textField.endOfDocument
        textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
    }
}
