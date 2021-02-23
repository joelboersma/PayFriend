# Team Name: Steve give us Jobs

# Homework 4

## Overview
This code should successfully implement all components of Homework 4. It was developed using the released Homework 3 solutions as a starting point.

## New Functions, Protocols, and Modifications

### SceneDelegate.swift
__Modifications__

  * Inside the `scene()` method, if a valid auth token is found in `Storage`, then the Home View is shown instead of the Login View. To do this an instance of the `HomeViewController` is instantiated, and then a navigation controller is instantiated with that `HomeViewController` instance as the root. Then the window's root view controller is set to the navigation controller. Finally, the window is shown and made the key window.

### HomeViewController.swift
__Modifications__

  * Made the class a delegate for protocol CreateAccountDelegate (which is defined in CreateViewController.swift). This allows information from the Create View to be passed back to the Home View and used for Api calls.
  * Added "+" (Create Account) button to the view controller

__Functions__

  * @IBAction func didPressCreate(_ sender: Any) - This method is called when the user presses the `+` button in this view controller. It instantiates the Create View Controller and set's the `accountNames` field of the view controller to be all the account names currently stored in the wallet. Then it sets the Create View Controller's delegate and finally present's the view.
  
  * func createAccountWithName(accountName: String) - This method is called when the `Create` button is pressed in the Create View Controller. It is a protocol stub that conforms the `HomeViewController` class to the `CreateAccountDelegate` protocol. It calls `Api.addNewAccount` in order to add a newly inputted account given by the string `accountName`. Once the new account is added, the completion updates the local `accounts` array with the new set accounts from the server and reloads the tableview.
  
  * func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) - This method is called when a row in the tableview is selected. It instantiates the Account View Controller and gets the name and amount from the corresponding row. It then sets the Account View Controller's `accountAmount`, `accountName`, `accountIndex`, `accounts`, `userWallet` fields. At the end it shows the Account View Controller.


### CreateViewController.swift
This is associated with the "Create Account" custom pop-up. It determines a default account name (uses lowest available number) and displays it as placeholder text in the text field. It keeps track of the text written in the text field, and when user taps "Create", it passes in the appropriate account name to a delegate function which will implement the Api call. It then dismisses the view controller. 

__Functions__
  * override func viewDidLoad() - Immediately empties `errorLabel` and gets the default account number to display in the placeholder of the `accountNameTextField` by calling `findNextAvailableNum`.
  
  * @IBAction func didBeginEditingText(_ sender: Any) - When the `accountNameTextField` is touched in this view controller the tap gesture recognizer is enabled.
  
   * @IBAction func didTap(_ sender: Any) - When the tap gesture recognizer recognizes a tap outside of the `accountNameTextField` then the view will end editing, the `accountNameTextField` will resign responder, and the tap gesture recognizer will be disabled.
  
  * @IBAction func didPressCreate(_ sender: Any) - This method is called when the `Create` button is pressed in this view controller. If the `accountNameTextField` is empty then the home view controller will delegate what occurs with the method `createAccountWithName` and input `defaultAccountName`. If the `accountNameTextField` is not empty then an error message will appear if the inputted account name is already in the wallet, else it will get the home view controller to delegate what occurs with the method `createAccountWithName` and user inputted `newName`.

  * func getDefaultAccountName() -> String - This method is used to get the default account name that will display as a placeholder within the `accountNameTextField` and use it if the user input is empty. It begins by declaring an integer variable `num` initialized to 0. Then it performs a case-insenitive check to see if there is an account in the user's wallet with the name `"Account \(num)"`. If not, `num` is increased by 1 and the check is performed again. This continues until the loop generates an account name that is not found in the wallet. This account name is then returned.
  

__Protocols__
  * protocol CreateAccountDelegate - Contains the blueprint of the method `createAccountWithName` that is implemented by the classes that adopt this protocol.

### AccountViewController.swift
This is associated with the Account View. It displays up-to-date account information, and it presents the appropriate alert/pop-up for deposits, etc when prompted to. It makes the Api calls for withdrawals, deposits, transfers, and deletions as necessary. 

__Modifications__
  * This class was made a TransferDelegate, which allows information from the Transfer View to be passed back to this view and used for Api calls.

__Functions__
  * override func viewDidLoad() - Sets `accountNameLabel`'s text to `accountName` and `accountAmountLabel`'s text to a formatted version of `accountAmount` by calling `formatMoney` on `accountAmount`. It also sets all the buttons' corner radius to 26, stores them in a UIBUtton array `buttons`, and enables the delete button's user interaction.
  
  * override func viewWillAppear(_ animated: Bool) - calls `updateAccountView()`
  
  * @IBAction func didPressDone(_ sender: Any) - calls `returnToHomeVC()`
  
  * @IBAction func didPressDeposit(_ sender: Any) - presents a UIAlertController `depositAlert` that allows users to enter deposit amount, after which Api.deposit is called on the entered amount and account view is updated by calling `updateAccountView()`
  
  * @IBAction func didPressWithdraw(_ sender: Any) - presents a UIAlertController `withdrawAlert` that allows users to enter withdrawal amount, after which Api.withdraw is called on the entered amount and account view is updated by calling `updateAccountView()`
  
  * @IBAction func didPressTransfer(_ sender: Any) - presents view controller `transferVC`
  
  * @IBAction func didPressDelete(_ sender: Any) - determines chosen account using `self.accountIndex` and deletes it by calling `Api.removeAccount` on chosen account and returning to home VC by calling `returnToHomeVC()`. 
  
  * func returnToHomeVC() - sets accounts by calling `Api.setAccounts` and returns to home view by calling `setViewControllers` on an array contaning only the controller with identifier "home"
  
  * func transferMoney(amount: Double, toAccountIndex: Int) - determines fromAccountIndex (index of account being transferred from) using `self.accountIndex` and transfers the money by calling `Api.transfer` and passing in the fromAccountIndex and toAccountIndex. Lastly, this function calls `updateAccountView()`.
  
  * func updateAccountView() - determines index of account to be updated using `self.accountIndex` and updates `accountAmount` to the amount of the account at determined index in `userWallet`
  
  Reused function from Home View Controller (which was also part of HW 3 given solutions)
  * func formatMoney(amount: Double) -> String

### TransferViewController.swift
This is associated with the "Transer" custom pop-up. It keeps track of the transfer amount entered in the text field and the "to" account chosen in the UIPicker. When the user clicks "Transfer" on the custom pop-up, it raises an error if needed and otherwise passes the transfer amount and "to" account to a delegate function, func transferMoney(), which will make the Api call. The view controller then dismisses.

__Functions__
  * override func viewDidLoad()
  
  * @IBAction func didBeginEnteringAmount(_ sender: Any)
  
  * @IBAction func didPressTransfer(_ sender: Any)
  
  * @IBAction func didTap(_ sender: Any)
  
  * func numberOfComponents(in pickerView: UIPickerView) -> Int
  
  Functions for UIPickerViewDelegate:
  * func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
  
  * func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
  
  * func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
  

__Protocols__
  * protocol TransferDelegate
  
## Comprehension Sources
  * https://learnappmaking.com/uialertcontroller-alerts-swift-how-to/
    * used to understand UIalertcontroller
  * https://www.youtube.com/watch?v=NP7H_LjTZGw
    * used to understand custom popups
  * https://codewithchris.com/uipickerview-example/
    * used to understand UIPickerview
