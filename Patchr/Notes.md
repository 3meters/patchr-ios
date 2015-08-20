Data Store
----------

Singleton entities

- All entities are saved in the data store wrapped as managed objects. 
- All upsert operations key on id_ to ensure there is only one copy of a particular entity in the store.
- Every time an entity is reloaded from the service, it's properties overwrite the ones in the data store. 
- If a property is missing from the map, then the data store object property will be set to nil.
- NOTE: Object properties are not overwritten if not present. What happens if something like photo should be set to nil?
- When an object is updated, every query item it is linked to is tickled so lists pick up the change.

- ServiceData objects do not go into the managed store.
- Singleton property objects are pushed into the store and are not shared: photo, location, richtype, link, provider
- Singleton property objects are deleted when the parent is deleted.
- Shortcuts are managed and shared. They are not deleted when the parent is deleted.

Queries

- Hold a set of query items.
- Each query item has pointers to an entity and the parent query.
- Each entity has a collection of the query items they are associated with.
- A new collection of query items are assembled for each query call.
- If entity being loaded from service is not currently associated with a query item then one is created.
- If entity being loaded from service is already associated with a query item then it replaces it and the query
  item is reused as part of the new collection.
- At an intermediate processing stage, the collection of query items for a query is a merging of any previous
  query items and new ones.
- As a final step in processing, any previous query items are checked to see if they
  are part of the new collection. If not then they are deleted from the data store.