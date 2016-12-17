Notifications
-------------

BADGING AND UNREAD

** Data Tracking Local ** 

When a remote notification is received, group and channel unread counts are incremented.
If the application is in the background then app badge is incremented too. The associated
message is tracked as unread in an unread map in the Notification controller. 

** Data Tracking Persisted ** 

When a remote notification is received, the priority for the members channel link is
set to zero so it sorts to the top.

** Data Tracking Clearing ** 

- App Badge: Bringing app to the foreground always clears the app badge.
- Group Badge: Setting the current group sets the group unread count to zero.
- Channel Badge: Setting the current channel sets the channel unread count to zero. Viewing 
  a channel restores it's priority to normal. 
- Message Indicator: Viewing a message in channel view controller will clear the unread
  flag in the notification controller unread map. 

** UI Tracking **

App icon shows badge. Group and channel items show badge with count based on count tracking
in notification controller. Messages show an unread indicator.
