# Framed Msgpack RPC

Framed Msgpack RPC (FMPRPC) is an RPC system for node.js.  It allows
clients to call remote procedures on servers.  An RPC consists of: (1)
a simple string name; (2) an argument that is a single JSON object;
(3) a reply that is also a single JSON object.  Of course, those
objects can be arrays, or dictionaries, so arguments and return values
can be complex and interesting.

FMPRPC is a variant of the
[Msgpack-RPC](http://redmine.msgpack.org/projects/msgpack/wiki/RPCDesign)
protocol specification for node.js.  Msgpack-RPC communicates
binary JSON objects that are efficiently encoded and decoded with the
[MessagePack](http://msgpack.org) serialization format. 

"Framed" Msgpack-RPC differs from standard Msgpack-RPC in a small way:
the encoding of the length of the packet is prepended to each
packet. This way, receivers can efficiently buffer data until a full
packet is available to decode. In an event-based context like node.js,
framing simplifies implementation, and yields a faster decoder,
especially for very large messages.

By convention, RPCs are grouped into _programs_, which can have
one or more _versions_.  Each (prog,vers) pair then has a collection
of procedures, meaning an RPC is identified unabmiguously by a 
(prog,vers,proc) triple.  In practice, these three strings are
joined with "." characters, and the dotted triple is the RPC name.

Due to framing, this protocol is not compatible with existing
Msgpack-RPC systems.  This implementation supports TCP transports only
at the current time.

## Example

The simplest way to write a server is with the `Server`
class as below:

```javascript
var rpc = require('framed-msgpack-rpc');
var srv= new rpc.Server ({
    programs : {
        "myprog.1" : {
            add : function(arg, response) {
                response.result(arg.a + arg.b);
            }
        }
    },
    port : 8000 
});
srv.listen(function (err) {
    if (err) {
        console.log("Error binding: " + err);
    } else {
        console.log("Listening!");
    }
});
```

a corresponding client might look like:

```javascript
var x = rpc.createTransport({ host: '127.0.0.1', port : 8000 });
x.connect(function (err) {
    if (err) {
        console.log("error connecting");
    } else {
        var c = new rpc.Client(x, "myprog.1");
        c.invoke('add', { a : 5, b : 4}, function(err, response) {
            if (err) {
                console.log("error in RPC: " + err);
            } else { 
                assert.equal(9, response);
            }
            x.close();
        });
    }
});
```

Or, equivalently, in beautiful 
[IcedCoffeeScript](https://github.com/maxtaco/coffee-script):

```coffee
x = rpc.createTransport { host: '127.0.0.1', port : 8000 }
await x.connect defer err
if err
    console.log "error connecting"
else
    c = new rpc.Client x, "myprog.1"
    await c.invoke 'add', { a : 5, b : 4}, defer err, response
    if err? then console.log "error in RPC: #{err}"
    else assert.equal 9, response
    x.close()
```

## Installation

It should work to just install with npm:
   
    npm install -g framed-msgpack-rpc

If you install by hand, you will need to install the one dependency,
which is the [the Purepack Msgpack library](http://github.com/maxtaco/purepack),
available as `purepack` on npm:

    npm install -g purepack


## Full API Documentation

If you are building real applications, it's good to look deeper than
the simple API introduced above. The full library is based on an
abstraction called an FMPRPC *Transport*.  This class represents a
stream of FMPRPC packets.  Clients and servers are built on top of
these streams, but not in one-to-one correspondence.  That is, several
clients and several servers can share the same Transport object. Thus,
FMPRPC supports multiplexing of many logically separated
application-level streams over the same underlying TCP stream.

### Transports

The transport mechanics are available via the submodule `transport`:

```javascript
var rpc = require('framed-msgpack-rpc');
var transport = rpc.transport;
```

Transports are auto-allocated in the case of servers (as part of the listen
and connect process), but for clients, you'll find yourself allocating and
connecting them explicitly.

All transports are *stream transports* and for now are built atop TCP
streams.  Eventually we'll roll out support for Unix domain sockets, but there
is no plan for UDP support right now.

#### transport.Transport

```javascript
var x = new transport.Transport(opts);
```
Make a new TCP transport, where `opts` are:

* `port` - the port to connect to
* `host` - the host to connect to, or `localhost` if none was given
* `path` - the path to connect to, if using Unix domain sockets
* `tcp_opts` - TCP options to pass to node's `net.connect` method, which 
 is `{}` by default
* `log_obj` - An object to use to log info, warnings, and errors on this 
 transport.  By default, the default logging to `console.log` will be used.
 See *Logging* below.
* `do_tcp_delay` - By default, the `Transport` will `setNoDelay` on
 TCP streams, but if you specify this flag as true, that behavior will
 be suppressed.
* `hooks` - Hooks to be called on connection error and EOF. Especially
 useful for `RobustTransport`s (see below).  The known hooks are
    * `hooks.connected` - Called when a transport is connected
    * `hooks.eof` - Called when a transport hits EOF.
* `dbgr` - A debugging object.  If set, it will turn on RPC tracing
 via the given debugging object. See _Debugging_ below.  I would have liked
 to call this a `debugger`, but that's a reserved keyword in node.
 

The following two options are used internally by `Server` and `Listener`
classes, and should not be accessed directly:
* `tcp_stream` - Wrap an existing TCP stream 
* `parent` - A parent listener object

#### transport.RobustTransport

```javascript
var x = new transport.RobustTransport(opts, ropts);
```

A subclass of the above; with some more features:

* If disconnected, will attempt to reconnect until successful.
* Will queue calls issued in between a disconnect and a reconnect.
* Will warn of RPCs that are outstanding for more than the given
 threshholds.

The `opts` dictionary is as in `Transport`, but there are additional
options that can be specified via `ropts`:

* `reconnect_delay` - a float - the number of seconds to wait between
 connection attempts.
* `queue_max` - the maximum number of RPCs to queue while reconnecting
* `warn_threshhold` - RPCs that take more than this number of seconds
 are warned about via the logging object.
* `error_threshhold` - RPCs that take more than this number of seconds
 are errored about via the logging object. Also, a timer will be set
 up to warn after this many seconds if the RPC isn't completed in time,
 while the RPC is still outstanding.

#### transport.Transport.connect

```javascript
x.connect(function (err) { if (!err) { console.log("connected!") } });
```

Connect a transport if it's not already connected. Takes a single callback,
which takes one parameter --- an error that's null in the case of a 
success, and non-null otherwise. In the case of a `RobustTransport`, the
callback will be fired after the initial connection attempt, but will continue
to reconnect in the background. Additional error and warnings are issued
via the logger object, and an `info` is issued when a connection succeeds.
Also, if a `hooks.connected` was passed, it will be called on a successful
connection, both the first time, and after any subsequent reconnect.

#### transport.Transport.is_connected

```javascript
var b = x.is_connected();
```

Returns a bool, which is `true` if the transport is currently connected,
and `false` otherwise.

#### transport.Transport.close

```javascript
x.close()
```

Call to actively close the given connection.  It will trigger all of the
regular hooks and warnings that an implicit close would.  In the case
of a `RobustTransport`, the transport will not attempt a reconnection.

#### transport.Transport.remote_address

```javascript
var ip = x.remote_address();
```

Get the IP address of the remote side of the connection.  Note that this
can change for a RobustTransport, if the DNS resolution for the given
hostname was updated and the connection was reestablished.  Will
return a string in dotted-quad notation.

#### transport.Transport.get_generation

```javascript
var g = x.get_generation()
```

Get the generation number of this stream connection.  In the case of a
regular Transport, it's always going to be 1.  In the case of a
`RobustTransport`, this number is incremented every time the
connection is reestablished.


#### transport.Transport.get_logger

```javascript
var l = x.get_logger()
```

If you want to grab to the logger on the given transport, use this
method.  For instance, you can change the verbosity level with
`x.get_logger().set_level(2)` if you are using the standard logging
object.

#### transport.Transport.set_logger

```javascript
x.set_logger(new logger.Logger({prefix : ">", level : logger.WARN}));
```

Set the logger object on this Transport to be the passed logger. 
You can pass a subclass of the given `Logger` class if you need
custom behavior to fit in with your logging system.

#### transport.Transport.set_debugger

```javascript
x.set_debugger(obj)
```

Set a debugging object on a transport.  After this is done, the core
will report that an RPC call was made or answered, either on the
server or client. See *Debugging* below for more details.

#### transport.Transport.set_debug_flags

```javascript
x.set_debug_flags(flags)
```

Call `set_debugger` as above but with an object that will be allocated.
The object is of type `debug.Debugger`, and is initialized with flags
given by `flags`. All debug traces are set to transport's logger object
at the `log.levels.DEBUG` level.

These flags can either be in numerical form (e.g., `0xfff` ) or string
literal form (e.g., `"a1m"`).  If in the latter form, the flags will
be converted into the numerical form via `sflags_to_flags`.

#### transport.createTransport or rpc.createTransport

```javascript
var x = rpc.createTransport(opts)
```

Create either a new `Transport` or `RobustTransport` with just one call.
The `opts` array is as above, but with a few differences.  First, the
`opts` here is the merge of the `opts` and `ropts` above for the case
of `RobustTransport`s; and second, an option of `robust : true` will
enable the robust variety of the transport.

Note that by default, I like function to use underscores rather than
camel case, but there's a lot of functions like `createConnection` 
in the standard library, so this particular function is in camel
case.  Sorry for the inconsistency.

### Clients

`Clients` are thin wrappers around `Transports`, allowing RPC client
calls.  Several clients can share the same Transport.  Import the
client libraries as a submodule:

```javascript
var client = require('framed-msgpack-rpc').client;
```

The API is as follows:

#### client.Client

Make a new RPC client:

```
var c = new client.Client(x, prog);
```

Where `x` is a `transport.Transport` and `prog` is the name of an RPC
program.  Examples for `prog` are of the form `myprog.1`, meaning the
program is called `myprog` and the version is 1.

Given a client, you can now make RPC calls over the specified connection:

#### client.Client.invoke

Use a Client to invoke an RPC as follows:

```javscript
c.invoke(proc, arg, function(err, res) {});
```

The parameters are:

* proc - The name of the RPC procedure.  It is joined with the
 RPC `program.version` specified when the client was allocated, yielding
 a dotted triple that's sent over the wire.
* arg - A JSON object that's the argument to the RPC.
* cb - A callback that's fired once there is a reply to the RPC. `err`
is `null` in the success case, and non-null otherwise.  The `res` object is
optionally returned in a success case, giving the reply to the RPC.  If
the server supplied a `null` result, then `res` can still be `null` in
the case of success.

#### client.Client.notify

As above, but don't wait for a reply:

```javscript
c.notify(proc, arg);
```

Here, there is no callback, and no way to check if the sever received
the message (or got an error).  Notifying seems weird to me, but it
was in the original MsgpackRpc system, so it's reproduced here.

### Servers

To write a server, the programmer must specify a series of *hooks*
that handle individual RPCs.  There are a few ways to achieve these
ends with this library.  The big difference is what is the `this`
object for the hook.  In the case of the `server.Server` and
`server.SimpleServer` classes, the `this` object is the server itself.
In the `server.ContextualServer` class, the `this` object is a
per-connection context object.  The first two are good for most cases.

You can get the server library through the submodule server:

```javascript
var server = require('framed-msgpack-rpc').server;
```

But most of the classes are also rexported from the top-level module.

#### server.Server

Create a new server object; specify a port to bind to, a host IP
address to bind to, and also a set of RPC handlers.

```javascript
var s = new server.Server(opts);
```

For `opts`, the fields are:

* `port` - A port to bind to
* `host` - A host IP to bind to
* `path` - A socket path to bind to, if being run on as Unix domain socket.
* `TransportClass` - A transport class to use when allocating a new
 Transport for an incoming connection.  By default, it's `transport.Transport`
* `log_obj` - A log object to log errors, and also to assign to 
  (via `make_child`) to child connections. Use the default log class
  (which logs to `console.log`) if unspecified.
* `programs` - Programs to support, following this JSON schema:

```javascript
{
    prog_1 : {
        proc_1 : function (arg, res, x) { /* ... */ },
        proc_2 : function (arg, res, x) { /* ... */ },
        /* etc ... */
    },
    prog_2 : {
        proc_1 : function (arg, res, x) { /* ... */ }
    }
}
```

Each hook in the object is called once per RPC.  The `arg` argument is
the argument specified by the remote client.  The `res` argument is
what the hook should call to send its reply to the client (by calling
`res.result(some_object)`).  A server can also reject the RPC via
`res.error(some_error_string)`).  The final argument, `x`, is the
transport over which the RPC came in to the server.  For instance, the
server can call `x.remote_address()` to figure out who the remote
client is.

#### server.SimpleServer

A `SimpleServer` behaves like a `Server` but is simplified in some
ways.  First off, it only handles one program, which is typically
set on object construction.  Second off, it depends on inheritance;
I've used CoffeeScript here, but you can use hand-rolled JavaScript
style inheritance too. Finally, it infers your method hooks: on
construction, it iterates over all methods in the current object,
and infers that a hook of the form `h_foo` handles the RPC `foo`.

Here's an example:

```coffeescript
class MyServer extends server.SimpleServer

  constructor : (d) ->
    super d 
    @set_program_name "myprog.1"

  h_reflect : (arg, res, x) -> res.result arg
  h_null    : (arg, res, x) -> res.result null
  h_add     : (arg, res, x) -> res.result { sum : arg.x + arg.y }
```

Most methods below are good for both `SimpleServer` and `Server`.
The former has a few extra; see the code in [server.iced](https://github.com/maxtaco/node-framed-msgpack-rpc/blob/master/src/server.iced).

#### server.ContextualServer

Here's an example:

```coffeescript
class Prog1 extends server.Handler
  h_foo : (arg, res) -> 
    console.log "RPC to foo() from #{@transport.remote_address()}"
    res.result { y : arg.i + 2 }
  h_bar : (arg, res) -> res.result { y : arg.j * arg.k }

class Prog2 extends server.Handler
  h_foo : (arg, res) -> res.error "not yet implemented"
  h_bar : (arg, res) -> res.error "not yet implemented"

s = new server.ContextualServer 
   port : 8881 
   classes : 
     "prog.1" : Prog1
     "prog.2" : Prog2
        
await s.listen defer err
console.log "Error: #{err}" if err?
```

This code constructs a `server.ContextualServer` with a `classes`
object that maps program names to classes. Whenever a new connection
is established in the above example, a new `Prog1` object and a new
`Prog2` object is created.  The former will handle all RPCs to
`prog.1` on that connection; the latter will handle all RPCs to
`prog.2`. Note that the `this` object here is per-connection, not
per-server.  This allows you to store all sorts of interesting
per-connection state. For more info, please see
[server.iced](https://github.com/maxtaco/node-framed-msgpack-rpc/blob/master/src/server.iced).

#### server.Server.listen

Bind to a port, and listen for incoming connections

```javascript
s.listen(function(err) {});
```

On success, the callback is fired with `null`, and otherwise,
an error object is passed.

#### server.Server.listen_retry

As above, but keep retrying if binding failed:

```javascript
s.listen_retry(delay, function(err) {});
```

The retry happens every `delay` seconds.  The given function is called
back with `null` once the reconnection happens, or with the actual
error if it was other than `err.code = 'EADDRINUSE'`.

#### server.Server.close

Close a server, and give back its port to the OS.

#### server.Server.set_port

Before calling `listen`, you can use this method to set the port
that the `Server` is going to bind to.

#### server.Server.walk_children

Walk the list of children, calling the specified function on each
child connection in the list:

```javascript
s.walk_children (function(ch) {});
```

### Logging Hooks

As you could imagine, an RPC can generate a lot of errors, warnings, and
informational messages.  Examples include: unmarshalling failures, 
unexpected EOFs, connection breaking, unhandled RPCs, etc. 

This package has an extensible logging system to fit in with your 
application, and a default logging system that should work for a lot
of cases too.

The basic classes can be found in the `log` submodule, accessible as:

```javascript
var log = require('framed-msgpack-rpc').log;
```

When a new `Listener` or `Transport` class is instantiated, it will
need a new logger object (note that `Listener` is the base class for the
various `Server` classes).  It will try the following steps to pick a
`log.Logger` object:

1. Access the `opt.log_obj` passed to the `Transport` or `Listener` 
  constructor.  This is often times an object of a custom subclass
  of `log.Logger`.
1. If that is was not specified, allocate a new `log.Logger` object:
     1. If `log.set_default_logger_class` was previous called, allocate
        one of those objects.
     1. Otherwise, allocate a `log.Logger` object.

Once this `log.Logger` object is allocated, the `Transport` or
`Listener` class will call `set_remote` on it, so that subsequent log
lines will show which client or server generated the message.

Logging is via the following methods, in ascending order of severity:

```javascript
log.Logger.debug(msg)
log.Logger.info(msg)
log.Logger.warn(msg)
log.Logger.error(msg)
log.Logger.fatal(msg)
```

They all, by default, write the message `msg` to `console.log` while
prepending the `remote_address` supplied above.  The default log level
is set to `log.levels.INFO`, but you can set it to `log.levels.WARN`,
`log.levels.ERRORS`, etc.  Warnings at lower levels will be silently
swallowed.  For the default logger object, the method
`log.Logger.set_level` can be used to set the logging level as desired.

To make a custom logger class, you can subclass `log.Logger`, or use
duck-typing: just make sure your class implements `set_remote` and the
five leveled logging methods above.

See `VLogger` in `test/all.iced` for one example of a different logger
--- it's used to make the regression tests look pretty.

See [log.iced](https://github.com/maxtaco/node-framed-msgpack-rpc/blob/master/src/log.iced) for more details.

### Debugging and Tracing

An debugger is a JavaScript object that is passed into the FMPRPC core,
and if available, is used to dump RPC debug traces. These debuggers can
be installed when a `Transport` is allocated, by specifying the
`opts.dbgr` option, or by calling `set_debugger` on most
FMPRPC objects.

If a debugging object is active, it is `call`ed with `debug.Message`
object when an RPC comes in or goes out.  The `debug.Message` object
contains a bunch of fields:

```coffeescript
F =
  METHOD : 0x1
  REMOTE : 0x2
  SEQID : 0x4
  TIMESTAMP : 0x8
  ERR : 0x10  
  ARG : 0x20
  RES : 0x40
  TYPE : 0x80
  DIR : 0x100          # which direction -- incoming or outgoing?
```

Debugging objects can choose to spam some or all of these fields,
depending on how bad the bug is.  For most purposes, the supplied
`debug.Debugger` makes a nice debugger object that you can easily tune
to print only the fields of your choosing (via the `flags` parameter).

See [debug.iced](https://github.com/maxtaco/node-framed-msgpack-rpc/blob/master/src/debug.iced) for more details.

## Internals

### Packetizer

To come. See [packetizer.iced](https://github.com/maxtaco/node-framed-msgpack-rpc/blob/master/src/packetizer.iced) for details.

### Dispatch

To come. See [dispatch.iced](https://github.com/maxtaco/node-framed-msgpack-rpc/blob/master/src/dispatch.iced) for details.

