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

# BTS api call

- our app is a person in a restaurant (let's call her Ada). The restaurant's kitchen is the Server, where all the data (the food) is stored.

  Now, Ada can't just walk into the kitchen. She needs a Waiter to take her order to the kitchen and bring the food back.

  In your app, the lib/apis/ directory is full of these "waiters". The most important one is lib/apis/api.dart, which is like the head waiter who knows the basic rules for talking to the kitchen.

  Let's look at the code. First, I'll read the main "waiter" file, api.dart.Of course! Let's break down how the app fetches data, explaining it like you're 10.

  Imagine your app is a person in a restaurant (let's call her Ada). The restaurant's kitchen is the Server, where all the data (the food) is stored.

  Now, Ada can't just walk into the kitchen. She needs a Waiter to take her order to the kitchen and bring the food back.

  In your app, the lib/apis/ directory is full of these "waiters". The most important one is lib/apis/api.dart, which is like the head waiter who knows the basic rules for talking to the kitchen.

  Let's look at the code. First, I'll read the main "waiter" file, api.dart.
  ╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
  │ ✔ ReadFile lib\apis\api.dart │
  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
  ✦ Excellent. I've read the "head waiter" file, lib/apis/api.dart.

  This file does two main things:

  1.  It knows the kitchen's address:

  1 String apiUrl = Config.baseUrl + 'connector/api/';
  This line builds the basic address for all API calls, like https://your-website.com/connector/api/.

  2.  It knows how to talk to the kitchen staff (the server): The getHeader function prepares the "special language" (headers) needed for any request, especially the Authorization part, which is
      like a secret password to prove you're allowed to ask for data.

  1 getHeader(String? token) {
  2 return {
  3 'Content-Type': 'application/json',
  4 'Accept': 'application/json',
  5 'Authorization': 'Bearer $token'
  6 };
  7 }

  Now, let's see how another, more specific "waiter" uses this. We'll look at lib/apis/user.dart to see how it fetches user details.
  ╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
  │ ✔ ReadFile lib\apis\user.dart │
  ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
  ✦ Great! Now we have the second piece.

  Here is the whole story of how the app gets data, from start to finish.

  The Analogy:

  - Your App: Ada, sitting at the table.
  - The Server (Kitchen): Where the data (food) is made.
  - lib/apis/api.dart: The Head Waiter. Knows the kitchen's address and the rules.
  - lib/apis/user.dart: A Specialist Waiter. Only handles orders about users.

  ***

  The Step-by-Step Action

  Let's say Ada (your app) wants to get the details of the currently logged-in user.

  Step 1: Ada gives an order to the Specialist Waiter.

  The app calls the get() function inside the user.dart file.

  Step 2: The Specialist Waiter prepares the order.

  This waiter already knows the kitchen's main address from the Head Waiter (.../connector/api/). It just adds its specific request: user/loggedin.

  Look at this code from lib/apis/user.dart:

        1 class User extends Api { // "extends Api" means it learns from the Head Waiter
        2   Future<Map> get(String? token) async {
        3     // 1. It builds the full address for the kitchen
        4     String url = "${apiUrl}user/loggedin";
        5
        6     // 2. It gets the secret password from the Head Waiter (getHeader)
        7     //    and sends the final order to the kitchen.
        8     var response = await http.get(Uri.parse(url), headers: getHeader(token));
        9

  10 // 3. It gets the food (data) and puts it on a plate the app can understand.
  11 var userDetails = jsonDecode(response.body);
  12 Map userDetailsMap = userDetails['data'];
  13 return userDetailsMap;
  14 }
  15 }

  The Flow is:

  1.  A screen in your app says, "I need the user's details!"
  2.  It calls the get() method in the User class.
  3.  The get() method builds the full URL: https://your-website.com/connector/api/user/loggedin.
  4.  It calls getHeader() to get the required Authorization token (the secret password).
  5.  It uses http.get() to send the request to the server.
  6.  The server sends back the user's data.
  7.  jsonDecode converts the data from a plain string into a Map that Dart can use.
  8.  The app gets the data and can now display the user's name, email, etc.

  So, api.dart provides the basic tools (the URL and headers), and other files like user.dart, sell.dart, etc., use those tools to make specific requests for different types of data.

  Yes, that's exactly right! You've got the main idea perfectly.

  Think of it like this:

  - api.dart is the Head Waiter. It knows the restaurant's address and the basic rules for talking to the kitchen.

  - attendance.dart, commission_agent.dart, contact.dart, printer.dart, and all the others in the lib/apis/ folder are Specialist Waiters.

  Each specialist waiter learns the basic rules from the Head Waiter and then adds their own specific knowledge.

  - The Attendance Waiter knows how to ask the kitchen for attendance records.
  - The Commission Waiter knows how to ask for commission agent data.
  - The Contact Waiter knows how to ask for customer information.

  They all extend Api, which is the code equivalent of "learning from the Head Waiter."

  Let's quickly peek at one more file, attendance.dart, to prove it.
  ╭───────────────────────────────────────╮
  │ ✔ ReadFile lib\apis\attendance.dart │
  ╰───────────────────────────────────────╯
  ✦ See? Right at the top:

  1 class AttendanceApi extends Api {

  It does the exact same thing we saw in user.dart. It extends Api so it can use this.apiUrl and this.getHeader() without having to define them again.

  This is a very smart and common way to write code. It keeps everything organized and avoids repeating the same code over and over.

### Buildpdfreceipt -> here flutter uses pdf package

- The pw. prefix is used to prevent a "name collision" between Flutter's own widgets and the widgets from the PDF creation library.

Here’s the simple explanation:

1.  Two Sets of Widgets: Your app uses two different sets of widgets that have the same names.

    - Flutter Widgets: These are the ones you use everywhere else to build the app's user interface (e.g., Text, Column, Row, SizedBox).
    - PDF Widgets: The pdf package has its own set of widgets for building the layout of a PDF document. It also calls them Text, Column, Row, SizedBox, etc.

2.  The Conflict: If you just imported both libraries, Dart wouldn't know which Text widget you want to use. The one for the screen, or the one for the PDF?

3.  The Solution (`as pw`): To solve this, we give the PDF widget library a prefix. The line at the top of the file, import 'package:pdf/widgets.dart' as pw;, tells Dart: "Every widget from
    this library must be prefixed with pw.".

So, inside the \_buildPdfReceipt method:

- pw.Text means: "Create a PDF Text element."
- pw.Column means: "Create a PDF Column."

And anywhere else in your app (like in the \_buildReceiptPreview method):

- Text means: "Create a Flutter Text widget to show on the screen."

It's a standard and necessary practice in Dart to keep the two libraries from getting confused.

- the long loading time is due to the sequential nature of the data fetching operations when the product page is initialized. I can significantly improve this by running these operations
  in parallel.

- by refactoring the \_initializePage method in lib/pages/products.dart to use Future.wait. This will allow the application to fetch all the necessary data concurrently, which should
  dramatically reduce the loading time.

analyzed products.dart and confirmed that the initState and didChangeDependencies methods are fetching data every time the page loads, causing the 5-10 second delay.

To resolve this, I'll use the AutomaticKeepAliveClientMixin to ensure the Products page state is preserved when switching between tabs. This will prevent the widget from being rebuilt and
the data from being re-fetched unnecessarily.

Here's my plan:

1.  Modify the ProductsState class to include the AutomaticKeepAliveClientMixin.
2.  Add the required wantKeepAlive getter, returning true.
3.  Call super.build(context) at the beginning of the build method, as required by the mixin.

Key Observations

1.  Shared Structure: All three files share a very similar overall structure:

    - Header (Logo, Business Info, Invoice No, Date)
    - Customer Info
    - Item Table (This is the main difference)
    - Totals Section (Subtotal, Discount, Tax, Total)
    - Footer (Notes, Barcode/QR Code)

2.  Primary Difference is the Item Table:

    - slim.blade.php: A detailed, multi-column table with headers for #, Description, Qty, Unit Price, Discount, and Subtotal. This looks like a standard 3-inch receipt.
    - slim2.blade.php: A more compact, line-item-focused layout. It shows the item name on one line and then the Qty x Price = Total on the line below it. This is a classic 2-inch receipt
      layout, designed to save horizontal space.
    - slim3.blade.php: This is a variation of the 3-inch receipt with slightly different columns in the item table: #, Description, Qty, MRP, Rate, and Amount. It also includes some PHP
      logic directly in the template to calculate discounts.

3.  Data Source: All templates pull data from a $receipt_details object. This is great because it means we can create a similar data structure in Flutter (likely from your Sell and Product
    models) and pass it to our new PDF generation logic.

The New Plan

We will now combine our previous work (the settings toggle) with this new understanding of the layouts.

1.  Create a `receipt_builder.dart`: I will create a new file, lib/helpers/receipt_builder.dart. This file will contain the core logic.

2.  Define the `ReceiptBuilder` Class: Inside this new file, I will create a class named ReceiptBuilder.

3.  Implement `buildReceiptPdf` Method: This class will have a central method, something like:

1 Future<Uint8List> buildReceiptPdf(String paperSize, dynamic receiptDetails) async {
2 // ... PDF generation logic ...
3 }

4.  Conditional Layout Logic: Inside buildReceiptPdf, we will use the paperSize parameter (which will come from our HomeProvider and the settings page) to decide which layout to build:

    - If paperSize == '2-inch', we will construct a PDF that mimics the layout of slim2.blade.php.
    - If paperSize == '3-inch', we will construct a PDF that mimics the layout of slim.blade.php.
    - If paperSize == '3-inch-alt', we will construct a PDF that mimics slim3.blade.php.

5.  Map Data: We will need to create a data class (like ReceiptDetailsModel) in Flutter that mirrors the structure of the $receipt_details object used in the Blade files. This will involve
    mapping data from your existing Sell, Contact, and Product models.

6.  Integrate with Printing: Finally, we will find the "Print" button in your UI (likely in checkout.dart or cart.dart), call our new ReceiptBuilder.buildReceiptPdf method, and pass the
    resulting PDF to the printing package.

Let's Start Building

I will now proceed with Step 1 & 2: creating the lib/helpers/receipt_builder.dart file and defining the basic ReceiptBuilder class structure.

After that, we can work on populating the PDF logic and the data model.

1. sarch functionality comes in main products page -> at statring of app the cursor must present in seearch feild
2. search feild must automatically add prodducts to cart no manual adding
3. create a settings section in banner , and adds dropdowwn flags , if the corresponding dropdowwn checked there theen it ll be mounted in product pag othrwwise it ll be unmoiunted from the products page
4. usee slim -2inch, slim2- 2 and 3 inch, slim3- 2 and 3 inch .blade files , to create layout that adapt the size of print sheet
5. blade files contain the logic and content for the dynamic layout ,
