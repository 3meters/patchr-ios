Firebase 
--------

** With Persistence: Calling 'once' **

Local update: A 'once' call will return the local value.

External update: First 'once' call will return local stale value if available. If not 
available, then will use network value which is correct. Second 'once' call will 
have correct value because first 'once' call causes a network sync even though
the subsequently updated local value is not returned to the first 'once' caller.

ISSUE: We don't have anyway to know that the returned value is from the local cache
and could be stale. If we want a data location to always be fresh even when there are no
current observers, use keepSynched.

** With Persistence: Calling 'observe' **

For the life of the observer, the target reference will be synced and correct. Initial 
callback will be stale if the value has been updated externally while not being observed.
Correct value will be returned in a second callback after a network sync.

Firebase Sorting

Always returned in ascending order.
- orderByChild order: null, false:key, true:key, numbers:key, strings:key, objects:key
- orderByKey: keys that parse as 32 int, strings
- orderByValue: same rules as orderByChild
