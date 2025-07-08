# oasis_windows_pos

A new Flutter project.

# Initiliztion

## Pages

- Login
- home
- Expenses

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Login Page -

- <dart:async> -> package lets us use timers,delays,future,timer.period() etc..
- <flutter/material.dart> -> main flutter UI tools (buttons,tet etc..)
- <cached_network_image> -> used to load image and keep them in memory
- <material_design_icon_flutter >-> lets us use good looking icons for eg we use in username and pass feild in login page
- <toast_helper.dart> -> this shows us pop up messages like wrong pass!
- <shared_preference.dart> -> this let our app saves small to mid size data on our local machine

- GlobalKey<FormState>() -> this generate a unique id (key)

- <TextEditingController()> -> this will helps us to hold the values in the textfeild.
  like if we save it in a var we can aceess it by `.text` property . we got what user types

- <focusNode()> -> this helps to focus on the particular feild and also to switch bw feilds

- `dispose()` -> method in `_loginState` , uses to clean up the mess in our login page
- actually it's a special methodd from flutter , get automatically called when we leave the screen

- <super.dispose()> - this ll tell flutter to run its default `dispose()`
- If we don’t clean up:

- we may get memory leaks

- our app could slow down or even crash

- Old timers might keep running in the background

## submitloginForm

- this function will get invoked when the user click the submit btn

# build

## Section - 1

- Stack => Allows you to layer widgets on top of each other like Photoshop layers

- positioned.fill -> makes both images blur cover the full screen

- image.asset -> helps to loads the image (i.e) oasis POS logo as fulscreen bg

- fit: BoxFit.cover -> makes sure image fills the screen with stretching

- backdrop.filter(filter: ) -> has some properties that give our image glassy effect

## Section - 3

- Align(alignment: Alignment(0, 0.6)) Positions the card below center but above bottom. (0, 0.6) means centered horizontally, 60% down vertically.

- ConstrainedBox(maxWidth: 380) -> Limits the card width to 380px max so it doesn’t stretch on big monitors.
- Container Holds the card look -> padding, rounded corners, semi-transparent background.
- BoxDecoration -> Gives it the glassmorphism style:

- color: white.withOpacity(0.12) -> Transparent glass look.

- borderRadius -> Rounded corners.

- border Subtle -> glowing glass border.

- padding: EdgeInsets.all(24) -> Internal spacing inside the card.
- Form Flutter’s built-in form validator wrapper.

# Home

## Function s in Home

### initState(): Initializes the state and calls other data-loading functions.

- homepageData(): Fetches user data, business details, and language preferences.
- checkIOButtonDisplay(): Determines the visibility of the check-in/check-out button.
- build(): Builds the UI, which is now cleaner but still has some logic.
- sync(): Handles the data synchronization process.
- getPermission(): Manages permissions for location, storage, and camera.
- loadStatistics(): Loads sales statistics from the local database.
- loadPaymentDetails(): Loads payment methods and details.\

## ryt now out home page is responsible for

- State management
- Buisness logic
- Building UI

# Fix

- Using provider for state management -> make home reactive to data changes, we r moving all our buisness logic inside Provider folder, that extends changeNotifier , from there using notifyListener() will helps home.dart to listen all changes
- Only UI will maintained by home.dart
- In components uner home each file ll responsibe each UI builds (Like components/home/statistics.dart ->resoponsible for build of cards in home page)
- This ll lead us to use this functionality on the other page (Widget Reusability)

# expenses.dart

## Purpose:

The main purpose of this screen is to allow users to input details about an expense and save it.

## UI (User Interface):

- It's a StatefulWidget named Expense.
- The screen has an AppBar with the title "Expenses".
- The body is a SingleChildScrollView containing a Form to hold the input fields.
- Input Fields:
  - Location: A dropdown (PopupMenuButton) to select the business location.
  - Tax: A dropdown to select an applicable tax rate.
  - Expense Category & Sub-Category: Two dependent dropdowns to classify the expense.
  - Expense Amount: A text field for the total expense amount, accepting only numbers.
  - Expense Note: A text field for any additional notes.
  - Payment Details: A section to input the payment amount, select the payment method (e.g., cash, card), and the payment account.

## State Management & Data Flow:

- The \_ExpenseState class manages the screen's state, including the values from text fields and dropdowns.
- Initialization (`initState`): When the screen loads, it fetches initial data for locations, taxes, and payment details.
- Dynamic Data Loading:
  - Selecting a location triggers fetching the relevant expense categories and payment methods for that location.
  - Selecting an expense category populates the sub-category dropdown.
- Submission (`onSubmit`):
  1.  It first checks for an active internet connection using Helper().checkConnectivity().
  2.  It validates the form to ensure required fields (like expense amount) are filled correctly.
  3.  It constructs an expense data object using ExpenseManagement().createExpense().
  4.  This data is sent to the server via an API call: ExpenseApi().create().
  5.  Upon successful submission, it navigates back to the previous screen and shows a success message using ToastHelper.

## Key Dependencies & Classes:

- `ExpenseApi`: Used for making network calls to the expenses API (e.g., creating a new expense).
- `System`: A model or helper class used to fetch system-wide data like locations, taxes, and payment methods.
- `ExpenseManagement`: A model class used to structure the expense data before sending it to the API.
- `Helper` & `ToastHelper`: Utility classes for common functions like checking connectivity and displaying user-friendly messages (toasts).
- `AppTheme`, `SizeConfig`, `MyLocalizations`: Helper classes for managing UI theme, screen size responsiveness, and internationalization (text translation).
