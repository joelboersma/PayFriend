//
//  HomeViewController.swift
//  PayFriend
//
//  Created by Joel Boersma on 1/26/21.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AddAccountDelegate {
    
    // MARK: Init
    
    var wallet: Wallet?
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var totalAmountLabel: UILabel!
    @IBOutlet weak var userNameSavedLabel: UILabel!
    @IBOutlet weak var accountsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stopView(withAlpha: false)
        self.userNameSavedLabel.isHidden = true
        self.tapGestureRecognizer.isEnabled = false
        self.userNameTextField.text = nil
        self.totalAmountLabel.text = nil
        self.accountsTableView.delegate = self
        
        if wallet == nil {
            // Get wallet info from server
            Api.user { response, error in
                if error == nil {
                    guard let user = response else {
                        assertionFailure("no user info")
                        return
                    }
                    self.wallet = Wallet(data: user, ifGenerateAccounts: false)
                    
                    self.walletViewSetup()
                    self.startView()
                }
                else {
                    print(error?.message ?? "no error message")
                }
            }
        }
        else {
            // Wallet was passed in from AccountViewController
            self.walletViewSetup()
            self.startView()
        }
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
    
    /// Set up wallet in view. Called only after getting wallet info from server.
    private func walletViewSetup() {
        self.wallet?.printWallet()
        self.accountsTableView.dataSource = self
        
        guard let walletInfo = self.wallet else {
            assertionFailure("no wallet info")
            return
        }
        
        // Set usernameTextField text
        // Defaults to phoneNumber if userName is empty
        let userName = walletInfo.userName ?? ""
        self.userNameTextField.text = userName == "" ? walletInfo.phoneNumber : userName
        
        // Set total amount in label
        self.displayDollarAmountInLabel(totalAmountLabel, amount: walletInfo.totalAmount)
        
        self.accountsTableView.reloadData()
    }
    
    /// Show userNameSaved message and hide it after 3 seconds.
    private func userNameSavedMessage() {
        // Enable userNameSavedLabel for 5 seconds
        self.userNameSavedLabel.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.userNameSavedLabel.isHidden = true
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
    
    
    // MARK: UITableViewDataSource Implementation
    
    /// Tells the data source to return the number of rows in a given section of a table view.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        guard let numAccounts = wallet?.accounts.count else {
            assertionFailure("can't find wallet accounts")
            return 0
        }
        return numAccounts
    }
    
    /// Asks the data source for a cell to insert in a particular location of the table view.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "accountCell")
        
        assert(indexPath.section == 0)
        guard let acccount = wallet?.accounts[indexPath.row] else {
            assertionFailure("no account")
            return cell
        }
        cell.textLabel?.text = acccount.name
        
        guard let detailTextLabel = cell.detailTextLabel else {
            assertionFailure("no detail text label in cell")
            return cell
        }
        self.displayDollarAmountInLabel(detailTextLabel, amount: acccount.amount)
        
        return cell
    }
    
    
    // MARK: UITableViewDelegate implementation
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        self.showAccountVC(index: indexPath.row)
    }
    
    
    // MARK: AddAccountDelegate implementation
    
    func addAccountWithName(_ name: String) {
        self.stopView(withAlpha: true)
        guard let unwrappedWallet = self.wallet else {
            assertionFailure("bad wallet")
            return
        }
        Api.addNewAccount(wallet: unwrappedWallet, newAccountName: name) {response, error in
            if error == nil {
                self.accountsTableView.reloadData()
            }
            else {
                print(error ?? "catch-all error")
            }
            self.startView()
        }
    }
    
    // MARK: IBActions
    
    /// When user taps an uninteractable part of the screen, hide the keyboard.
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            view.endEditing(true)
        }
    }
    
    /// When user presses "Log Out" button, show login view.
    @IBAction func logOutButtonPress(_ sender: Any) {
        self.showLoginView()
    }
    
    /// When user presses add button, show add account view
    @IBAction func addButtonPress(_ sender: Any) {
        self.showAddAccountVC()
    }
    
    /// When user begins editing userNameTextField, enable tapGuestureRecognizer.
    @IBAction func userNameEditingDidBegin() {
        tapGestureRecognizer.isEnabled = true
    }
    
    /// After user finishes editing userNameTextField, disable tapGestureRecognizer, send new userName to server, then show confirmation message upon success.
    @IBAction func userNameEditingDidEnd() {
        tapGestureRecognizer.isEnabled = false
        
        guard let newUserName = userNameTextField.text else {
            assertionFailure("no userNameTextField")
            return
        }
        
        if (newUserName.isEmpty) {
            self.userNameTextField.text = wallet?.phoneNumber
        }
        else {
            self.wallet?.userName = userNameTextField.text
            Api.setName(name: newUserName) { response, error in
                
                if error != nil {
                    print("userName update error")
                    return
                }
                
                self.userNameSavedMessage()
            }
        }
    }
    
    
    // MARK: Navigation

    /// Show LoginView (creates new view controller stack)
    private func showLoginView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginViewController = storyboard.instantiateViewController(identifier: "LoginViewController") as? LoginViewController else {
            assertionFailure("couldn't find login vc")
            return
        }
        
        // Set the stack so that it only contains login and animate it
        let viewControllers = [loginViewController]
        self.navigationController?.setViewControllers(viewControllers, animated: true)
    }

    /// Show AddAccountView
    private func showAddAccountVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let addAccountViewController = storyboard.instantiateViewController(identifier: "AddAccountViewController") as? AddAccountViewController else {
            assertionFailure("couldn't find addAccount vc")
            return
        }
        addAccountViewController.wallet = wallet
        addAccountViewController.delegate = self
        
        self.present(addAccountViewController, animated: true)
    }
    
    /// Show AccountView with account from specified index
    private func showAccountVC(index: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let accountViewController = storyboard.instantiateViewController(identifier: "AccountViewController") as? AccountViewController else {
            assertionFailure("couldn't find account vc")
            return
        }
        accountViewController.wallet = self.wallet
        accountViewController.accountIndex = index
        accountViewController.account = self.wallet?.accounts[index]
        
        let viewControllers = [accountViewController]
        self.navigationController?.setViewControllers(viewControllers, animated: true)
    }
}
