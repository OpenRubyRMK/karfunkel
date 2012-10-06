OpenRubyRMK Protocol documentation
==================================

These pages describe the protocol used between the OpenRubyRMK server
component, Karfunkel, and the clients. As a user, you are most
probably not interested in this. As a plugin writer, it depends on
what exactly you want to do with your plugin. As an implementor of a
new client, this is a must-read.

The OpenRubyRMK protocol is a stateful two-way protocol on top of
TCP. Clients establish a connection by sending the HELLO request and,
if the server is configured accordingly, their login credentials (this
is a TODO currently).

The protocol is XML-based (UTF-8-encoded), and consists of four major
components:

1. **The request**. A request is something that orders the other side of
   the connection to take action somehow.
2. **The response**. A response is a reaction to a request; it may
   either be a successful (like `ok`), an unsuccessful (like
   `rejected`), or a postponing (like `processing`) response.
3. **The notification**. A notification is a one-way information
   triggered by certain requests that cause global modifications that
   all clients need to know about (like loading a project). You don’t
   have to answer notifications, but a client will most likely want to
   update its user interface when it receives a notification.
4. **The command**. A command the meta-structure sent to and from the
   server. It acts as a container for any number of requests,
   responses and notifications, and allows you (and Karfunkel) to sent
   multiple informations in a single chunk of data.

TODO: Write more docs, about request and response IDs, give examples
for actual XML, etc.

Contents
--------

* [Requests](requests/index.html)
  * [Categories](requests/categories.html)
  * [Global scripts](requests/global_scripts.html)
  * [Maps](requests/maps.html)
  * [Project Management](requests/project_management.html)
  * [Server Management](requests/server_management.html)
  * [Tilesets](requests/tilesets.html)
* [Responses](responses/index.html) (TODO)
* [Notifications](notifications/index.html) (TODO)

License
-------

This documentation is provided under the same terms as the
OpenRubyRMK.

%% Local Variables:
%% mode: text
%% eval: (yas-load-directory "../../.yasnippet")
%% End:
