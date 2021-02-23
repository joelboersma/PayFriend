# ECS 189E WQ 2021 Homework 1
Joel Boersma - 914845830

## Description
This project tasked us with making a launch screen and a login view for a cryptocurrency wallet app.

### Launch Screen
The launch screen features a name for the app, PayFriend, and a logo from Google's [Material Design](https://material.io/resources/icons/?search=wallet&icon=account_balance_wallet&style=outline).

### Login View
The login page displays a welcome message and a prompt requesting that the user log in using their phone number. 

Below these are two text fields: one for the country code and another for the remaining 10 digits of the phone number. The former defaults to "+1" (US & Canada) and cannot be interacted with by the user. The latter will automatically format the text to look like standard phone number notation as the user types within.

When the user taps on the text field, the iOS numeric keyboard will appear. Tapping anywhere on the screen will remove it.

Below the two text fields is a "Next" button that by default is gray but will be green when a valid phone number is entered. If the user pushes the button at this point, the entered phone number will display in E.164 format beneath the two text fields. If the user pushes the button when a valid phone number is not displayed, one of three error messages will display until either the button is pushed again or a valid phone number is entered.

## Implementation

### Phone Number Text Field

The text field in which a user enters a 10-digit phone number is called `phoneNumberTextField` and is an instance of the class `PhoneNumberTextField` from the `PhoneNumberKit` library. When tapped, the iOS numeric keyboard will appear. This text field utilizes an `AsYouTypeFormatter` so that, as the user types within it, the text field will automatically format its inner text to look like a phone number.

The placeholder text for `phoneNumberTextField` is set to "(888) 888-8888". This is so that the user will intuitively know to enter their 10-digit number rather than their seven-digit.

The `withPrefix` property of `phoneNumberTextField` is set to `false` when the view loads. This is so that a country code is not accepted when typed in the field. In its current state, this app only accepts phone numbers with a "+1" country code.

Every time the text in `phoneNumberTextField` is changed, it is checked to see if the entered phone number is valid. Updates are sent to the error label and the "Next" button accordingly.

### "Next" Button

The "Next" button, called `nextButton`, is gray by default, and is green only if the phone number in `phoneNumberTextField` is valid. This color updates each time `phoneNumberTextField.text` is updated.

When the user clicks `nextButton`, an optional call to `phoneNumberTextField.phoneNumber` is called. This call to the `phoneNumber` property will return the current phone number if and only if it is a valid phone number. If it is invalid, an error message will display (See "Error Messages" section below). If the number is valid, we reformat it to fit the E.164 standard using `PhoneNumberKit.format` and display it on the screen.

### Error Messages and Phone Number Display

Error messages and the final E.164 phone number both use the same `UILabel` instance, called `errorLabel`. This label's `textColor` is red when displaying an error and black when displaying a phone number.

When `nextButton` is pushed after entering an invalid number, one of three error messages will display in `errorLabel` with red text.. This error message stays until either `nextButton` is pushed again or until a valid phone number is entered.

These are the three possible errors that are checked for:
- No Number: the text field is empty.
- Invalid Format: the phone number entered is not 10 digits (not including the country code).
- Invalid Number: the phone number is invalid, despite correct formatting
    - Example: (222) 222-2222. Perhaps there is no area code (222)?

Which error statement to choose is actually determined by the length of the string in the text field.

When a valid number is submitted, it is displayed in `errorLabel` with black text. It will remain until `nextButton` is pushed again.

### Dismissing the Keyboard

The login view contains a `UITapGestureRecognizer` to recognize when a non-interactive part of the view is tapped. When this happens, `handleTap` is called. It checks the state of the `UITapGestureRecognizer`, and if it is `.ended` (meaning the user has lifted their finger from the screen), the view is forced to end editing.
