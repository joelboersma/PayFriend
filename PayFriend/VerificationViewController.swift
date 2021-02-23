//
//  VerificationViewController.swift
//  PayFriend
//
//  Created by Joel Boersma on 1/25/21.
//

import UIKit
import PhoneNumberKit

class VerificationViewController: UIViewController {

    // MARK: Init
    
    var phoneNumberKit = PhoneNumberKit()
    var phoneNumber: PhoneNumber?
    var phoneNumberString = ""
    var phoneNumberE164 = ""
    
    @IBOutlet weak var instructionSubtitle: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var otpView: OTPView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.stopAnimating()
        guard let temp: PhoneNumber = phoneNumber else {
            assertionFailure("no phone number")
            return
        }
        phoneNumberString = temp.numberString
        phoneNumberE164 = phoneNumberKit.format(temp, toType: .e164)
        
        instructionSubtitle.text = "Enter the code sent to \(phoneNumberString)"
        errorLabel.text = ""
    }
    
    // MARK: Helpers
    
    private func showErrorMessage(_ message: String) {
        errorLabel.text = "Error: \(message)"
    }
    
    private func checkCode() {
        guard let code = otpView.moveCursor() else {
            // Code unfinished
            return
        }
        
        stopView(withAlpha: false)
        
        Api.verifyCode(phoneNumber: phoneNumberE164, code: code, completion: { response, error in
            // handle response and error
            if error == nil {
                // Store E164 number and auth token
                guard let authToken = response?["auth_token"] as? String else {
                    assertionFailure("no auth token")
                    return
                }
                Storage.authToken = authToken
                Storage.phoneNumberInE164 = self.phoneNumberE164
                
                self.showHomeVC()
                self.startView()
                
            }
            else {
                guard let errorMessage = error?.message else {
                    assertionFailure("no error message")
                    self.startView()
                    return
                }
                self.showErrorMessage(errorMessage)
                self.startView()
            }
        })
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
    
    @IBAction func tf0Edit() {checkCode()}
    @IBAction func tf1Edit() {checkCode()}
    @IBAction func tf2Edit() {checkCode()}
    @IBAction func tf3Edit() {checkCode()}
    @IBAction func tf4Edit() {checkCode()}
    @IBAction func tf5Edit() {checkCode()}
    
    @IBAction func resendButtonPush() {
        Api.sendVerificationCode(phoneNumber: phoneNumberE164, completion: { response, error in
            if error == nil {
                self.errorLabel.text = ""
                self.otpView.resetAll()
            }
            else {
                print(error?.message ?? "what")
            }
        })
    }
    
    // MARK: Navigation
    
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
