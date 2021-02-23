//
//  TransferViewController.swift
//  PayFriend
//
//  Created by Joel Boersma on 2/13/21.
//

import UIKit

protocol TransferDelegate {
    func transferMoney(amount: Double, toAccountIndex: Int)
}

class TransferViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // Passed in from Account VC
    var account: Account?
    var wallet: Wallet?
    
    // Not passed in from Account VC
    var accountNames: [String] = []
    var pickerIndex = 0
    
    var delegate: TransferDelegate?
    
    @IBOutlet weak var accountPicker: UIPickerView!
    @IBOutlet weak var transferAmountTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var transferButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        errorLabel.text?.removeAll()
        
        self.accountPicker.dataSource = self
        self.accountPicker.delegate = self
        
        self.accountNames = self.wallet?.accounts.filter{$0.name != self.account?.name}.map{$0.name} ?? []
        if accountNames.count == 0 {
            self.accountPicker.isUserInteractionEnabled = false
        }
        
        transferAmountTextField.becomeFirstResponder()
        
        transferButton.isUserInteractionEnabled = true
    }
    
    
    // MARK: IBActions
    
    @IBAction func transferButtonPress() {
        if let text = transferAmountTextField.text, let transferAmount = Double(text), let _account = account {
            // check for invalid amount entry
            if transferAmount > _account.amount {
                errorLabel.text = "Amount entered is too high"
            } else if transferAmount < 0.01 {
                errorLabel.text = "Must withdraw at least $0.01"
            }
            // if transfer amount is valid -> proceed with Api call
            else {
                self.delegate?.transferMoney(amount: transferAmount, toAccountIndex: pickerIndex)

                // return to account
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: UIPickerViewDataSource Implementation
    
    /// Called by the picker view when it needs the number of components
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // Always one column
        return 1
    }
    
    /// Called by the picker view when it needs the number of rows for a specified component.
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return max(self.accountNames.count, 1)
    }
    
    /// Called by the picker view when it needs the title to use for a given row in a given component.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if self.accountNames.count > 0 {
            return self.accountNames[row]
        }
        else {
            transferButton.isUserInteractionEnabled = false
            transferButton.backgroundColor = UIColor.gray
            return "No Other Accounts"
        }
    }
    
    /// Called by the picker view when the user selects a row in a component.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.pickerIndex = row
    }
    
    
    // MARK: Navigation

    
    
}
