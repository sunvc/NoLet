# How Privacy Can Be Leaked <!-- {docsify-ignore-all} -->

The route of a push notification from sending to receiving is:<br>
Sender <font color='red'> →Server①</font> → Apple APNS Server → Your Device → <font color='red'>NoLet APP②</font>.

Privacy may be leaked at the two red points <br>
* The sender does not use HTTPS or uses a public server *(the author can see request logs)*
* The NoLet App itself is not secure, and the version uploaded to the App Store has been modified.

#### Solving Server-side Privacy Issues
* You can use the open-source backend code to [deploy your own backend service](/deploy.md) with HTTPS enabled.
* Use [encrypted push notifications](/encryption) with custom keys to encrypt the push content.

#### Ensuring the APP is Built Entirely from Open-Source Code
To ensure the App is secure and has not been modified by anyone (including the author), NoLet is built by Apple Xcode Cloud and then uploaded to the App Store.

*This does not consider whether iOS itself leaks privacy*