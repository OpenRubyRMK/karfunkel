Requests/Project management
===========================

_Projects_ are the top-level entity of nearly everything Karfunkel
deals with. Therefore, there exists a good number of requests
specifically dedicated at managing them in some way. You can find all
of them in this section.

+[warn]+++++++++++++++++++++++++++++++++
### Attention

Karfunkel can maintain multiple opened projects at once, but only
operate on the currently _active_ one. You may want to instruct
Karfunkel to activate another project before requesting to change it.
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## close_project

Removes a project from the list of currently loaded projects. If the
project is the active one, deselects it (Karfunkel has no active
project after this, so you want to send another request selecting
another project). Prior to removing, the project’s current state is
saved out to disk.

### Parameters

id
: The project ID of the project you want to close.

### Responses

ok
: The project was successfully closed.

### Notifications

* `project_selected`. Only sent if the active project was closed. The
  notification’s `id` field is set to `-1`.
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## delete_project

Closes a project (see [close_project](#closeproject)) and then
recursively deletes the project directory from the file system. After
this, there is no way back.

### Parameters

id
: The ID of the project to delete.

### Responses

ok
: The project was successfully deleted.

### Notifications

* `project_selected`. Only sent if the active project was deleted. The
  notification’s `id` field is set to `-1`.
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## load_project

Instructs Karfunkel to load a specified project from the filesystem
and automatically makes it the active one.

### Parameters

path
: The path to the project directory on the filesystem.

### Responses

ok
: Everything is fine, the project was loaded and now is the active
  one. The response has a parameter `id` that contains the project ID
  the loaded project got assigned.

### Notifications

* `project_selected`
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## new_project

Creates an empty project and makes it the active one.

### Parameters

path
: Directory where to store the new project.

### Responses

ok
: The project was successfully created. The `id` parameter contains
  the project ID the new project got assigned.

### Notifications

* `project_selected`
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## save_project

Saves the active project out to disk.

### Responses

ok
: The project was successfully saved.
++++++++++++++++++++++++++++++++++++++++

%% Local Variables:
%% mode: markdown
%% eval: (add-to-list 'yas-snippet-dirs "../../../.yasnippet")
%% End:
