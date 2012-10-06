Requests/Tilesets
=================

A _tileset_ is a collection of graphics to be used on a map, combined
into a single image that can be tiled (hence the name) usually in
squares of 32x32px.

+[request]++++++++++++++++++++++++++++++
## new_tileset

Upload a tileset onto the server, making it available for use on new
maps.

### Parameters

name
: The name the tileset will be filed under on the server. Spaces are
  converted to underscores and the whole name is converted to
  lowercase. If the name doesn’t end in `.png`, this file extension is
  appended automatically.

picture
: The tileset’s PNG data, encoded in Base64.

### Responses

ok
: The tileset was successfully stored on the server.

### Notifications
* `tileset_added`
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## delete_tileset

Removes a tileset from the server.

+[warn]+++++++++++++++++++++++
### Caution!
Maps using this tileset will be invalidated, but not
deleted!
++++++++++++++++++++++++++++++

### Parameters

name
: The name of the tileset to delete.

### Responses

ok
: The tileset was successfully deleted.

### Notifications
* `tileset_deleted`
++++++++++++++++++++++++++++++++++++++++

%% Local Variables:
%% mode: text
%% eval: (yas-load-directory "../../../.yasnippet")
%% End:
