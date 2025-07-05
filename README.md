# oasis_windows_pos

A new Flutter project.

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
- s<hared_preference.dart> -> this let our app saves small to mid size data on our local machine

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
