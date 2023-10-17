# VRC-RoboScout
An iOS application to automate the scouting process for the VEX Robotics Competition.

[![](https://dcbadge.vercel.app/api/server/7b9qcMhVnW)](https://discord.gg/7b9qcMhVnW)

## Contributions are being accepted
Contributors will have to sign a CLA as VRC RoboScout is a published iOS application.

## Building from source for testing
Testing is strongly encouraged and incredibly valuable during this stage of development. Please feel free to do so and give feedback on the [development Discord server](https://discord.gg/7b9qcMhVnW).

Below are the steps you must follow:

1. Download Xcode. You can do this from the MacOS App Store.
2. On the main repository page, select `Open with Xcode` in the `Code` menu (see image below).

![Screenshot 2023-06-11 at 3 57 38 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/1a227b72-5274-4d1c-927e-bdc96e96c637)

3. Select a destination for the project to be cloned on your computer. `Trust and Open` the project when prompted.
4. Wait for Xcode to load the project. You have successfully cloned VRC RoboScout to your computer!
5. You will now generate your own RobotEvents token to allow VRC RoboScout to interact with the RobotEvents API. To do this, first head over to the RobotEvents API homepage [here](https://www.robotevents.com/api/v2).
6. In the `Request Access` page, fill out the form and request access (see image below).

![Screenshot 2023-06-11 at 4 35 02 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/c5eed9b0-61e1-4795-ac7e-e33493d232fe)

7. Requests are approved instantly. Next, select the new `Access Tokens` page where the `Request Access` page previously was (see image below).

![Screenshot 2023-06-11 at 4 41 00 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/5b86baa9-d1fa-4bb3-9d63-ef4984750baf)

8.  Press the `Create New Token` button. Name your token `VRC RoboScout`, and press `Create` (see image below).

![Screenshot 2023-06-11 at 4 41 56 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/91fbd829-5c67-4636-ad0a-bc554a8c1e29)

9. **Copy your token now.** You will not be able to see it again and will have to generate a new one if you lose it (see image below).

![Screenshot 2023-06-11 at 4 48 12 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/2e09f1bb-0e9f-4c6a-b107-066815142b36)

10. In Xcode, press `Product` on the menu bar at the top of your screen. Then press `Scheme`, then `Edit Scheme...` (see image below).

![Screenshot 2023-06-11 at 4 56 30 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/ddc1852d-58ab-425a-8805-bcc538c02ecc)

11. Select `Run` on the left menu bar. In the `Environment Variables` section, press the `+` icon to create a new environment variable. **You MUST name it ROBOTEVENTS_API_KEY, or else the app will not work!** Paste your token in the `Value` area.

![Screenshot 2023-06-11 at 5 02 01 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/ce807ea0-ee4e-4a9e-8740-143f7e99f276)

12. Select a build target at the top bar (see image below) to choose the simulator or physical device you wish to run VRC RoboScout on! The default is the latest iPhone simulator, but you may run VRC RoboScout on any iPhone or iPad on iOS or iPadOS 16 or greater.

![Screenshot 2023-06-11 at 5 55 24 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/a6e9abe3-3cad-44b1-9e39-520626ec8b5e)

13. [OPTIONAL] If you wish to build to a physical device, such as your iPhone or iPad, you will need to follow additional steps such as enabling developer mode and trusting the computer on your device. A guide on enabling developer mode for your iOS device can be found on [the Apple developer website](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
14. You are now ready to build and install VRC RoboScout! With your device or simulator selected, press the play button (see below) to build, install, and run VRC RoboScout! If you are running it on your physical device, you will need to trust the developer profile before being able to open the app. A guide for that can be found [here](https://osxdaily.com/2021/05/07/how-to-trust-an-app-on-iphone-ipad-to-fix-untrusted-developer-message/).

![Screenshot 2023-06-11 at 6 00 47 PM](https://github.com/SunkenSplash/VRC-RoboScout/assets/62484109/d765223e-d815-4d73-9f0b-0f87747e5eff)

15. [OPTIONAL] Please join the VRC RoboScout Discord server [here](https://discord.gg/7b9qcMhVnW) to share your feedback! You are now also eligible to become a beta tester for VRC RoboScout. Please ping a developer in the server for the `Beta Testers` role and access to beta testing channels if you are interested!
