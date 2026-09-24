# How Privacy Can Be Leaked <!-- {docsify-ignore-all} -->

The route a push notification takes from sending to receiving is:<br>
Sender <font color='red'> →Server①</font> → Apple APNS / HarmonyOS push server → Your Device → <font color='red'>Nolet APP②</font>.

Privacy may be leaked at the two red points <br>
* The sender does not use HTTPS or uses a public server *(the author can see request logs)*
* The Nolet App itself is not secure, and the version uploaded to the App Store has been modified.

#### Solving Server-side Privacy Issues
* You can use the open-source backend code to [deploy your own backend service](/en/deploy.md) with HTTPS enabled.
* Use [encrypted push notifications](/en/encryption) with custom keys to encrypt the push content.

#### Ensuring the APP is Built Entirely from Open-Source Code
To ensure the App is secure and has not been modified by anyone (including the author), Nolet is built by Apple Xcode Cloud and then uploaded to the App Store.

*This does not consider whether iOS itself leaks privacy*
