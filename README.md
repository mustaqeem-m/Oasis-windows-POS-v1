# oasis_windows_pos

A new Flutter project.

# Initiliztion

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
