Notifications
-------------

UNREADS

** Unread state **

All unread state is tracked in the service database at the message, channel, group,
and user level. 

** Patchr Cloud ** 

- Unread flagging when messages are created (via notification queue)
- Manage channel sorting to promote channels with unread messages
- Manage user total unreads counter
- Clear unreads on message, channel, group delete
- Clear unreads when leaving channel, group


BADGING

- App icon shows badging based on user unread counter. Set via remote notification
  or direct from firebase database.
- Drawer button shows user unread counter in-sync with app icon.
- Group and channel pickers show unread counts via firebase.
- Messages show unread indicator via firebase.

** Clearing ** 

Unread clearing is done at the message level when the user actively views the message. 
Additional clearing is done based on deletions and leaving channels/groups.
Channel sorting is returned to normal when no remaining unreads. 


REMOTE NOTIFICATIONS

** iOS 10.1 **

App in foreground
- didReceiveRemoteNotification (willPresent is also an option that we do not use)

App running in background
- didReceiveRemoteNotification

App running in background: tap notification
- didReceive

App killed by user
- App is not launched, badging must be delivered with notification.

App suspended by system
- App is launched, badging based on badge notification property.

** iOS 9.0 or less **

Exceptions to above:

App running in background: tap notification
- didReceiveRemoteNotification (state == .inactive)
