# Chat App
A real time chat application where users can register/login and have one-to-one chat with other registered users.

## Features
- User can register with name, email and password.
- Registered user can login with email and password.
- User can edit name by going in profile section, and also logout and relogin with different user.
- User can see list of all registered users and latest message on home screen.
- User can message any user one-to-one and it will be updated in real time, all message history is also loaded with recent at bottom.

## Approach Taken
- Used `Firebase Auth` for login and register users.
- Used `Firebase Realtime Database` to save user data and messages.
- Used `MessageKit` for showing real time messages on conversation screen.
- Used `InputBarAccessoryView` to handle send action in messaging.

## Steps to run project
- Open `ChatApp.xcodeproj` directly in Xcode and run the application target on simulator. If you want to run it on device, you need to add development team id in Signing and Capabilities.
- Register user and you will see list of other registered users and their latest message on home screen. Currently I have already registered a user with `name: Nishant Kumar` and `email: nishant@gmail.com`. You can go on edit and logout to register another users.
- Click on name and you can send one-to-one message to that user.
- You can also run app on two parallel simulators and login with different user to have real time conversation.

## Future Improvements
- Offline support
- Handle message status, timestamp and typing indicator.
- Group chat
- Media sharing
