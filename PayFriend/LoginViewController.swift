//
//  LoginViewController.swift
//  HW1-Wallet
//
//  Created by Joel Boersma on 1/12/21.
//

import UIKit
import PhoneNumberKit

class LoginViewController: UIViewController {
    
    // MARK: Init
    
    let phoneNumberKit = PhoneNumberKit()
    
    var errorTextInvalidFormat = "Error: Number should be of format:\n+1 (555) 555-5555"
    var errorTextInvalidNumber = "Error: Invalid number"
    var errorTextNoNumber = "Error: You must enter a phone number"
    
    @IBOutlet weak var phoneNumberTextField: PhoneNumberTextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var clearButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        phoneNumberTextField.withPrefix = false;
        disableNextButton()
        errorLabel.text = ""
        activityIndicator.stopAnimating()
        clearButton.isHidden = true
        
        // Check if phone number is in storage
        guard let phoneNumberE164 = Storage.phoneNumberInE164 else {
            print("no phone number in storage")
            return
        }
        
        // Show formatted phone number in phoneNumberTextField
        // Based on https://github.com/marmelroy/PhoneNumberKit/blob/master/Documentation/OXMIGRATIONGUIDE.md
        do {
            let phoneNumber = try phoneNumberKit.parse(phoneNumberE164, withRegion: "US")
            let formattedNumber: String = phoneNumberKit.format(phoneNumber, toType: .national)
            print("Stored number: \(formattedNumber)")
            phoneNumberTextField.text = formattedNumber
            enableNextButton()
            clearButton.isHidden = false
        }
        catch {
            print("Generic parser error")
        }
    }
    
    // MARK: Helpers
    
    func enableNextButton() {
        nextButton.backgroundColor = .systemGreen
    }
    
    func disableNextButton() {
        nextButton.backgroundColor = .systemGray
    }
    
    func displayPhoneNumber(_ E164Number: String) {
        errorLabel.textColor = .label
        errorLabel.text = E164Number
    }
    
    func showErrorLabel() {
        errorLabel.textColor = .red
        let textLength = phoneNumberTextField.text?.count
        switch(textLength) {
        case 0:
            errorLabel.text = errorTextNoNumber
        case 14:
            // Valid format, but invalid number
            // Example: (222) 222-2222
            errorLabel.text = errorTextInvalidNumber
        default:
            errorLabel.text = errorTextInvalidFormat
        }
    }
    
    /// Disables view interaction and shows activity indicator
    func stopView(withAlpha: Bool) {
        self.activityIndicator.startAnimating()
        if withAlpha {
            view.alpha = 0.5
            navigationController?.navigationBar.alpha = 0.5
        }
        view.isUserInteractionEnabled = false
        navigationController?.navigationBar.isUserInteractionEnabled = false
    }
    
    /// Enables view interaction and hides activity indicator
    func startView() {
        self.activityIndicator.stopAnimating()
        view.alpha = 1
        navigationController?.navigationBar.alpha = 1
        view.isUserInteractionEnabled = true
        navigationController?.navigationBar.isUserInteractionEnabled = true
    }
    
    // MARK: IBActions
    
    @IBAction func nextButtonPush(_ sender: Any) {
        guard let phoneNumber = phoneNumberTextField.phoneNumber else {
            showErrorLabel()
            return
        }
        if (phoneNumber.countryCode != 1) {
            // This should cover 22222222222
            showErrorLabel()
            return
        }
        let phoneNumberE164 = phoneNumberKit.format(phoneNumber, toType: .e164)
        print("Phone Number: " + phoneNumberE164)
        // displayPhoneNumber(phoneNumberE164)
        
        stopView(withAlpha: false)
        
        if Storage.authToken != nil, Storage.phoneNumberInE164 == phoneNumberE164 {
            // This user is the last successfully logged in user.
            self.showHomeVC()
            self.startView()
        }
        else {
            Api.sendVerificationCode(phoneNumber: phoneNumberE164, completion: { response, error in
                if error == nil {
                    self.showVerificationVC(sender: sender, phoneNumber: phoneNumber)
                    self.startView()
                }
                else {
                    self.errorLabel.textColor = .systemRed
                    self.errorLabel.text = "Error: \(error?.message ?? "what")"
                    self.startView()
                }
            })
        }
    }
    
    @IBAction func phoneNumberChange() {
        guard let phoneNumberText = phoneNumberTextField.text else {
            clearButton.isHidden = true
            return
        }
        if phoneNumberText.isEmpty {
            clearButton.isHidden = true
            return
        }
        clearButton.isHidden = false
        
        if phoneNumberTextField.isValidNumber && phoneNumberTextField.phoneNumber?.countryCode == 1 {
            enableNextButton()
            errorLabel.text?.removeAll()
        } else {
            disableNextButton()
        }
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        // Hide keyboard
        if sender.state == .ended {
            view.endEditing(true)
        }
    }
    
    @IBAction func clearButtonPress() {
        phoneNumberTextField.text?.removeAll()
        clearButton.isHidden = true
    }
    
    // MARK: Transition
    
    func showVerificationVC(sender: Any, phoneNumber: PhoneNumber) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let verificationViewController = storyboard.instantiateViewController(identifier: "VerificationViewController") as? VerificationViewController else {
            assertionFailure("couldn't find verification vc")
            return
        }
        
        verificationViewController.phoneNumber = phoneNumber
        navigationController?.pushViewController(verificationViewController, animated: true)
    }
    
    func showHomeVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let homeViewController = storyboard.instantiateViewController(identifier: "HomeViewController") as? HomeViewController else {
            assertionFailure("couldn't find home vc")
            return
        }
        
        // Set the stack so that it only contains home and animate it
        let viewControllers = [homeViewController]
        self.navigationController?.setViewControllers(viewControllers, animated: true)
    }
}
