# ECS 189E WQ 2021 Homework 2
Joel Boersma - 914845830

## Description
This project tasked us with expanding on the cryptocurrency wallet app that we began in the previous homework by creating a verification view and a navigation controller that allows for traversal between multiple views. The verification view utilizes both a one-time password (OTP) text field and an API for sending and verifying the one-time codes.

On the login view, once the user enters a valid phone number and clicks the "Next" button, a six-digit one-time code will be sent to their device via SMS. The user will then be brought to the verification view where they can then enter their one-time code. This can either be done digit-by-digit or by copying and pasting the code. The backspace key does not function in this case. The user can also click a "Resend Code" button to resend their code. Once a six digit code is entered, the app will check if the code is valid. If the code is invalid or has expired, the text field will be cleared and an error will display. Otherwise, the user will be sent to the home view.

The home view is not yet functional. For the time being, it simply displays a house icon. The user cannot return to previous views from the home view.

## Implementation

### API
The API for sending and verifying one-time codes was provided. 

When the user pushes the "Next" button on the login view, an API call is made that will send a verification code via SMS. If the `error` returned is `nil`, then the verification view will show. Otherwise, an error message will display. This same API call is made when the user pushes the "Resend Code" button.

When the user enters a six-digit code, another API call is made that will verify that the code entered is correct. If this is the case, the home screen will show. Otherwise, an error will display and the text field will be cleared.

The possible errors that can be returned by the API are as follows:
- "Incorrect verification code"
- "Your code expired"
- "Your phone number is invalid"
- "Network error"

Ideally, the last two would never occur. The app already checks if the phone number entered is valid before making an API call, and the API should be presumed to have no network errors.

### OTP Text Field

The OTP text view is actually made up of six separate text fields. The individual text fields are of the class `OTPTextField` which inherits from `UITextField`. The view that holds these text fields together is of the class `OTPView` which inherits from `UIStackView`.

The `OTPView` has an array of `OTPTextField` optionals and an `Int` to keep track of which text field is currently being edited in. By default, all `OTPTextField`s are uninteractable, but when the `OTPView` is initialized, the first `OTPTextField` becomes both interactable and the first responder.

Each `OTPTextField` has an `IBAction` attached to it that responds to the "Editing Changed" event and will call the method `checkCode`. It will check if a six-digit code has been fully entered through the `OTPView.moveCursor` method, which returns a string optional that will either contain the completed six-digit code or `Optional.none`. If the former is recieved, then the API will verify if the code is correct.

The method `movecursor` method in `OTPView` does more than return a String optional, though. When this method is called, the current text field is made uninteractable. Then, the method checks how many characters were entered into the text field. If more than one is entered (i.e. copy/paste), then a separate function `handleCopyPaste` is called and its return value is returned from this function. If one character is entered and the final `OTPTextField` is the most recently edited, then the completed one-time code is returned and the cursor returns to the beginning. Otherwise, the cursor moves to the next text field to the right, user interaction is enabled for this text field, this text field becomes the first responder, and `Optional.none` is returned.

The `handleCopyPaste` function also returns a String optional. This method is called when multiple characters are added into a text field at once. If this amount is not equal to 6 digits, then all text fields are cleared, the cursor moves to the beginning text field, and `Optional.none` is returned. If exactly 6 digits are pasted in, then the digits are distributed among the 6 text fields, and the code is returned.

If the entered code is invalid, then all text fields are cleared and made user-uninteractable, and then the first text field is made user-interactable and the first responder.

### Navigation

A navigation controller was added to the app for this assignment. 

On the login view, when the "Next" button is pushed after a valid phone number is entered, the verification view is pushed onto the view stack. In the verification view, there is a back button on the navigation bar to go back to the login view.

When a valid code is entered in the verification view, the app transitions to the home view. Rather than pushing the home view onto the stack, the stack is replaced by an array containing only the home view. This is so that the user has no way to navigate back to either of the previous pages.
