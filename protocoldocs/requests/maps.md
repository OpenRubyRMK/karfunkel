Requests/Maps
=============

A _map_ is a conglomerate of graphics from a given tileset,
characters, and other information.

+[request]++++++++++++++++++++++++++++++
## new_map

Create a new and empty map on the server. The map is automatically
made a root map.

### Parameters

name (optional)
: A name for the map. If left out, the name will be generated from the
ID the map gets assigned.

### Responses

ok
: A new map has been created. The `id` field contains the ID the map
  got assigned.

### Notifications

* `map_added`
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## delete_map

Deletes a map and recursively deletes all its child maps.

### Parameters

id
: The ID of the map to delete.

### Responses

ok
: The requested map(s) has/have been deleted successfully.

### Notifications
* `map_deleted`. Note this is only sent for the actual map requested
  to delete and is not repeated for the deleted child maps (as
  deleting the parent map obviously deletes the child maps as well).
++++++++++++++++++++++++++++++++++++++++

%% Local Variables:
%% mode: text
%% eval: (yas-load-directory "../../../.yasnippet")
%% End:
