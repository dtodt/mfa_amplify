# mfa

Mfa Amplify Sample

## How to setup

Configure the arguments at `.vscode/launch.json` or run the project passing on the necessary definitions.

- configure the aws user pool
  - sign in experience to Optional MFA;
  - device tracking to User opt-in and Trust remembered devices;
- configure a user pool user
  - define a phone_number to receive sms's;
  - enable mfa / sms to the user;

## How to reproduce the issue

Sign in into a device;
Then sign in into another device;

> An error will be thrown by the amplify library.

> The device will be connected correctly, but not remembered.
> Than the next time you sign in, it will ask for the code again.
