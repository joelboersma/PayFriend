//
//  AddAccountViewController.swift
//  PayFriend
//
//  Created by Joel Boersma on 2/10/21.
//

import UIKit

protocol AddAccountDelegate {
    func addAccountWithName(_ name: String)
}

class AddAccountViewController: UIViewController {

    // Mark: Init
    
    var wallet: Wallet?
    var delegate: AddAccountDelegate?
    
    @IBOutlet weak var accountNameTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.errorLabel.text = ""
        self.accountNameTextField.placeholder = self.getPlaceholderName()
        self.accountNameTextField.becomeFirstResponder()
    }
    
    // MARK: Helpers
    
    /// Gets the placeholder name for the account
    private func getPlaceholderName() -> String {
        guard let accounts = wallet?.accounts else {
            assertionFailure("No accounts list")
            return ""
        }
        
        // Start with "Account n + 1" where n = accounts.count
        // Decrease until account name doesn't yet exist
        var num = accounts.count + 1
        while (accounts.contains { $0.name.lowercased() == "account \(num)" }) {
            num -= 1
        }
        
        return "Account \(num)"
    }

    // MARK: IBActions
    
    /// When done button is pushed, check for errors and if none add the account
    @IBAction func doneButtonPress() {
        guard let accountName = accountNameTextField.text == "" ? accountNameTextField.placeholder : accountNameTextField.text else {
            assertionFailure("No valid account name")
            return
        }
        
        guard let accounts = wallet?.accounts else {
            assertionFailure("No accounts list")
            return
        }
        
        if accounts.contains(where: { $0.name.lowercased() == accountName.lowercased() }) {
            self.errorLabel.text = "Error: An account with that name already exists"
        }
        else {
            self.errorLabel.text?.removeAll()
            delegate?.addAccountWithName(accountName)
            self.dismiss(animated: true)
        }
    }

}
