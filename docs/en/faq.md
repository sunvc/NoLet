
*Thanks to the open source project [BARK](https://github.com/Finb/Bark)*

#### Unable to Receive Push Notifications
Check if the Device Token is normal in the App settings. If not, refer to [here](#Device-Token-Shows-Unknown)<br/>
If it's normal, try restarting your device. If you still can't receive push notifications, check if the push request returns status code 200.<br/>
If all checks are normal but you still have issues, you can provide feedback in the [NoLet Feedback Group](https://t.me/PushToMe).

#### Device Token Shows Unknown
This is likely because your device is not properly connected to Apple servers, accompanied by issues such as iMessage unavailability and inability to receive push notifications from other apps.<br/>
You can try switching networks, restarting your phone, or disabling VPN tools if you're using them to access Apple services.<br/>
This issue is related to the connection between your device and Apple servers. The developer cannot provide any assistance, and you need to try resolving it yourself.

#### Push Usage Limits
Normal requests (HTTP status code 200) have no limitations.<br>
However, if you exceed 1000 error requests (HTTP status codes 400, 404, 500) within 5 minutes, <b>your IP will be banned for 24 hours</b>.

#### Receiving Unknown Push Notifications, such as NoContent
Possible reasons:<br>
1. If you've sent push notifications using Safari, when typing any URL in Safari, the browser might autocomplete to a Bark API URL from your history, triggering a push notification through preloading.
2. If you've sent a Bark API URL to chat applications like WeChat File Assistant, WeChat may periodically request the URL, triggering push notifications.
3. Your push key may have been leaked. It's recommended to reset your key on the server list page.

#### Time-sensitive Notifications Not Working
Try <b>restarting your device</b> to resolve this issue.

#### Unable to Save Notification History, or Cannot Copy by Pulling Down Notifications Without Clicking the Copy Button
Try <b>restarting your device</b> to resolve this issue.<br />
This occurs when the push service extension ([UNNotificationServiceExtension](https://developer.apple.com/documentation/usernotifications/unnotificationserviceextension)) isn't running properly, preventing the notification saving code from executing correctly.

#### Automatic Push Content Copying Not Working
In iOS 14.5 and later versions, due to stricter permissions, the app cannot automatically copy push content to the clipboard when receiving notifications.<br/>
As a workaround, you can pull down the notification or swipe left on the lock screen notification and tap to view, which will automatically copy the content, or click the copy button on the push notification.

#### Default Opening to Notification History List
When reopening the APP, it will navigate to the last opened page.<br />
Simply stay on the message history page when exiting the APP, and the next time you open the APP, it will open to the message history page.

#### Does the Push API Support POST Requests?
NoLet supports both GET and POST requests, and supports using JSON.<br>
Regardless of the request method, the parameter names remain the same. Refer to the [Tutorial](/tutorial#request-methods) for more information.

#### Push Failure Due to Special Characters, Such as Links in Push Content, or Abnormal Pushing (e.g., + Becoming a Space)
This issue occurs due to improper URL formatting, commonly when manually concatenating URLs.<br>
When concatenating URLs, make sure to URL-encode the parameters.

```sh
# For example
https://wzs.app/key/{push_content}

# If {push_content} is
"a/b/c/"

# The final concatenated URL would be
https://wzs.app/key/a/b/c/
# This would not find the corresponding route, and the backend will return 404

# You should URL-encode {push_content} before concatenation
https://wzs.app/key/a%2Fb%2Fc%2F
```
When using mature HTTP libraries, parameters are automatically processed, and you don't need to manually encode them.<br>
However, if you're manually concatenating URLs, pay special attention to special characters in the parameters. **It's best to always apply URL encoding regardless of whether there are special characters or not**.

#### How to Ensure Privacy and Security
Refer to [Privacy and Security](/privacy)
