Requests/Server management
==========================

_Server management_ covers all requests that are not related to a
specific project in any way, but rather influence Karfunkel’s
behaviour in some way or another.

+[request]++++++++++++++++++++++++++++++
## Hello

The `hello` request verifies a connection to the server and is the
very first request a potential client has to sent to Karfunkel. If the
connection is judged trustworthy (currently it always is), the
connection is verified and you get an `ok` response. Otherwise you get
`rejected`.

### Parameters

None currently. This may change in the future.

### Responses

`ok`
: You have been accepted as a client. The response contains your ID
  for further requests to the server in `your_id`, the number of
  currently connected clients (including you) in `my_clients_num`, the
  name of the currently loaded project (if any) in `my_project` and
  the version of the remote server in `my_version`.

`rejected`
: You’re not allowed to send requests to this server.
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## Ping

A no-op request. The server always answers this as OK, and its solre
purpose is to keep the connection up and running even if no other
communication happens.

### Responses

Always causes an `ok` response.
++++++++++++++++++++++++++++++++++++++++

+[request]++++++++++++++++++++++++++++++
## Shutdown

Asks Karfunkel to terminate himself. Although the request is
immediately answered as being `ok`, Karfunkel now sends `shutdown`
requests to all currently connected clients. If all clients answer
these requests as being `ok`, he proceeds to the actual termination,
otherwise, nothing happens and the request is silently discarded.

### Responses

When sent to Karfunkel, the response always is an `ok`. If *you* get
such a request, Karfunkel has just ask you whether he is allowed to
terminate. If you answer `ok`, you’re fine with this; answer
`rejected` if you disagree.

### Remarks

The server administrator of course can terminate Karfunkel immediately
without any client consultation.
++++++++++++++++++++++++++++++++++++++++

%% Local Variables:
%% mode: text
%% eval: (yas-load-directory "../../../.yasnippet")
%% End:
