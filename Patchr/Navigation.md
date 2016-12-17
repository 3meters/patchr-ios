
NAVIGATION

The navigation UI is extremely tricky to get right because it has to shoulder a lot
of functionality:

- Display channels by group or for the current group
- Navigate to a channel
- Show unread badging for groups and channels and segments
- Show unread badging for navigation drawer button
- Show indicator for current channel
- Show indicators for private and/or starred channels
- Show commands to create a new channel/group
- Sort channels to emphasize unread and starred

UI Model

- Segment controller to switch between channels and direct messages.
- Channels sectioned by group

- UI Channels: Section header for group: two lines, expand/collapse, icon, title, role, unread badging
- UI Channels: Channel item: one line, starred, name, lock, unread badging

- UI Conversations: Section header for group: two lines, expand/collapse, icon, title, role, unread badging
- UI Conversations: Conversation item: one line, users, unread badging

- Sorting: Sections with unread sort to the top
- Sorting: Channels with unread sort to the top of the group
- Sorting: Starred channels sort above non-starred channels
