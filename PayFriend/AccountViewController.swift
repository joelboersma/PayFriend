//
//  AccountViewController.swift
//  PayFriend
//
//  Created by Joel Boersma on 2/13/21.
//

import UIKit

class AccountViewController: UIViewController, TransferDelegate {
    
    // MARK: Init
    
    var account: Account?
    var accountIndex: Int?
    var wallet: Wallet?
    
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.stopAnimating()
        self.accountNameLabel.text = account?.name
        displayDollarAmountInLabel(self.amountLabel, amount: self.account?.amount ?? 0)
    }
    
    
    // MARK: Helpers
    
    /// Formats the text in a label to display a dollar amount.
    /// Negative values will have the negative sign in front of the dollar sign.
    /// Positive values will have green text. Negative and zero values will have red text.
    /// String formatting modified from HW3 solution.
    private func displayDollarAmountInLabel(_ label: UILabel, amount: Double) {
        var amountString: String
        
        let charactersRev: [Character] = String(format: "$%.02f", abs(amount)).reversed()
        if charactersRev.count < 7 {
            amountString = String(format: "$%.02f", amount)
        }
        else {
            var newChars: [Character] = []
            for (index, char) in zip(0...(charactersRev.count-1), charactersRev) {
                if (index-6)%3 == 0 && (index-6) > -1 && char != "$"{
                    newChars.append(",")
                    newChars.append(char)
                } else {
                    newChars.append(char)
                }
            }
            amountString = String(newChars.reversed())
        }
        
        label.text = amount < 0 ? "-\(amountString)" : amountString
        label.textColor = amount > 0 ? .systemGreen : .systemRed
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
    
    /// Updates view with new acccount data after each operation
    func updateAccountView(){
        if let index = self.accountIndex, let _wallet = self.wallet, let _account = account {
            // updating amount in account var (is this necessary?)
            _account.amount = _wallet.accounts[index].amount
            // updating label to be correct amount
            displayDollarAmountInLabel(self.amountLabel, amount: _account.amount)
        }
    }
    
    
    // MARK: TransferDelegate Implementation
    
    func transferMoney(amount: Double, toAccountIndex: Int) {
        self.stopView(withAlpha: true)
        guard let fromAccountIndex = self.accountIndex else {
            assertionFailure("no account")
            return
        }
        guard let _wallet = self.wallet else {
            assertionFailure("no wallet")
            return
        }
        let _toAccountIndex = toAccountIndex >= fromAccountIndex ? toAccountIndex + 1 : toAccountIndex
        
        Api.transfer(wallet: _wallet, fromAccountAt: fromAccountIndex, toAccountAt: _toAccountIndex, amount: amount) {response, error in
            if let err = error {
                print(err)
            } else if let resp = response {
                print(resp)
            }
            self.updateAccountView()
            self.startView()
        }
    }
    
    // MARK: IBActions
    
    @IBAction func doneButtonPress(_ sender: Any) {
        self.showHomeVC()
    }
    @IBAction func depositButtonPress() {
        self.showDepositAlert()
    }
    @IBAction func withdrawButtonPress() {
        self.showWithdrawAlert()
    }
    @IBAction func transferButtonPress() {
        self.showTransferVC()
    }
    @IBAction func deleteButtonPress() {
        // Add an alert so that the user can confirm?
        guard let accIndex = self.accountIndex else {return}
        guard let wallet = self.wallet else {return}
        self.stopView(withAlpha: true)
        Api.removeAccount(wallet: wallet, removeAccountat: accIndex){response, error in
            if let err = error {
                print(err)
            } else if let resp = response {
                print(resp)
            }
            self.showHomeVC()
        }
    }
    
    // MARK: Alerts
    
    private func showDepositAlert() {
        self.stopView(withAlpha: true)
        
        let depositAlert = UIAlertController(title: "Deposit", message: "Please enter deposit amount below", preferredStyle: .alert)
        
        depositAlert.addTextField(configurationHandler: {textfield in
            textfield.placeholder = "Enter Amount"
                                    textfield.keyboardType = .decimalPad})
        
        depositAlert.addAction(UIAlertAction(title: "Deposit", style: .default, handler: { _ in
            // if user entered deposit amount, call Api.deposit
            if let strAmount = depositAlert.textFields?.first?.text, var depositAmount = Double(strAmount), let index = self.accountIndex, let _wallet = self.wallet {
                if (depositAmount < 0.01) {
                    depositAmount = 0
                }
                Api.deposit(wallet: _wallet, toAccountAt: index, amount: depositAmount) { response, error in
                    if let err = error {
                        print(err)
                    } else if let resp = response {
                        print(resp)
                    }
                    self.updateAccountView()
                    self.startView()
                }
            }
            else {
                self.startView()
            }
        }))
        
        depositAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.startView()
        }))
        
        self.present(depositAlert, animated: true)
    }
    
    private func showWithdrawAlert() {
        self.stopView(withAlpha: true)
        
        let withdrawAlert = UIAlertController(title: "Withdraw", message: "Please enter amount to withdraw below", preferredStyle: .alert)
        
        withdrawAlert.addTextField(configurationHandler: { textfield in textfield.placeholder = "Enter Amount"
            textfield.keyboardType = .decimalPad})
    
        withdrawAlert.addAction(UIAlertAction(title: "Withdraw", style: .default, handler: { action in
            if let strAmount = withdrawAlert.textFields?.first?.text, var withdrawAmount = Double(strAmount), let index = self.accountIndex, let accountAmount = self.account?.amount, let _wallet = self.wallet {
                // check if user entered valid amount, and adjust if necessary
                if withdrawAmount > accountAmount {
                    withdrawAmount = accountAmount
                }
                else if withdrawAmount < 0.01 {
                    // trying to withdraw less than 1 cent
                    withdrawAmount = 0
                }
                
                //with valid withdrawal amount, call Api.withdraw
                Api.withdraw(wallet: _wallet, fromAccountAt: index, amount: withdrawAmount) {response, error in
                    if let err = error {
                        print(err)
                    } else if let resp = response {
                        print(resp)
                    }
                    self.updateAccountView()
                    self.startView()
                }
            }
            else {
                self.startView()
            }
        }))
        
        withdrawAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.startView()
        }))
        
        self.present(withdrawAlert, animated: true)
    }
    
    // MARK: Navigation
    
    private func showTransferVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let transferViewController = storyboard.instantiateViewController(identifier: "TransferViewController") as? TransferViewController else {
            assertionFailure("couldn't find transfer vc")
            return
        }
        transferViewController.account = self.account
        transferViewController.wallet = self.wallet
        transferViewController.delegate = self
        
        self.present(transferViewController, animated: true, completion: {})
    }
    
    private func showHomeVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let homeViewController = storyboard.instantiateViewController(identifier: "HomeViewController") as? HomeViewController else {
            assertionFailure("couldn't find account vc")
            return
        }
        homeViewController.wallet = self.wallet
        
        let viewControllers = [homeViewController]
        self.navigationController?.setViewControllers(viewControllers, animated: true)
    }
}
