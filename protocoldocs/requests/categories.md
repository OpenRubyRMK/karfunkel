Requests/Categories
===================

_Categories_ are customisable collections of things. For instance, all
"items" form a category, all "weapons", etc. You are not limited to
the categories supplied by default, and you can always remove
categories you don’t want. They allow for a really easy management of
all the different kinds of collections over a single, unified
interface.

+[request]++++++++++++++++++++++++++++++
## new_category

Creates a new and empty category.

### Parameters

name
: The new category’s name, automatically converted to lowercase.

### Responses

ok
: The category was successfully added. The `name` field contains the
  category’s name.

### Notifications
* `category_added`
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## delete_category

Remove a category and all entries in it.

### Parameters

name
: The name of the category to remove.

### Responses

ok
: The category was deleted successfully.

### Notifications
* `category_deleted`
++++++++++++++++++++++++++++++++++++++++

%% Local Variables:
%% mode: text
%% eval: (yas-load-directory "../../../.yasnippet")
%% End:
