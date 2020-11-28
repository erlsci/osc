# osc

*Erlang support for the Open Sound Control protocol*

[![Build Status][gh-actions-badge]][gh-actions]
[![Erlang Versions][erlang-badge]][versions]
[![Tag][github-tag-badge]][github-tag]

[![Project Logo][logo]][logo-large]

This is an implementation of the Open Sound Control (OSC) protocol written
in Erlang with OTP. The project provides the following:

* `osc_lib`: an API for encoding and decoding OSC messages
* `osc_client`: a manageed UDP client for OSC servers
* `osc`: an OTP application (release-baseed) for creeating custom OSC servers

For more information about OSC, see the links below in the 
[Resources](#resources) section.

## Setup

Include one of the following in your project's `rebar.config`: 

``` erlang
%% Latest Release
{deps, [
    {osc, {git, "https://github.com/erlsci/osc", {tag, "2.0.0"}}}
]}.

%% Unstable
{deps, [
    {osc, {git, "https://github.com/erlsci/osc", {branch, "release/2.1.x"}}}
]}.
```

## Encoding / Decoding OSC Messagees

TBD

## Connecting to OSC Servers

The following is a demonstration using the Erlang OSC server, but first we need
to add the default addresses to the server:

``` erlang
1> osc:add_addresses().
```

Now we can create a client connection manager and send a message to the default
address:

``` erlang
2> osc_client:start().
3> {ok, Pid} = osc_client:connect("localhost", 2357).
4> osc_client:cast_msg(Pid, "/debug/log_message").
ok
```

No value is expected from the server, so `cast_msg` is used.

The Erlang OSC server will then log the output:

``` erlang
=INFO REPORT==== 27-Nov-2020::14:02:22.687276 ===
Received message: []
```

Here's an example of connecting to a SuperCollider server:

``` erlang
1> osc_client:start().
2> {ok, Pid} = osc_client:connect("localhost", 57110).
3> osc_client:call_msg(Pid, "/status").
{message,"/status.reply",
         [1,0,0,1,0,0.8447946310043335,8.175622940063477,4.41e4,
          44101.72468382008]}
```

`call_msg` was used here since we expect a value back from the server.

For more example usage, you may be interested in viewing the source for the
LFE project [undertone](https://github.com/lfex/undertone). While written in
LFE, it make extensive use of `osc_client` and might offer the curious coder
significant insights.

## Running Project Tests

    rebar3 as test check

## Running the Default Server

Start an interactive Erlang shell:

    rebar3 shell

Note: that will automatically start all the release dependency applications as
well as `osc` itself.

Then you can use the simple API for adding OSC addresses to the default server:

``` erlang
1> osc:get_addresses().
[]
2> osc:add_addresses().
[ok]
3> osc:get_addresses().
["/debug/log_message"]
4> osc:remove_addresses().
[ok]
5> osc:get_addresses().
[]
```
See the `osc` module for example payloads in adding and removing OSC addresses.


## Using `erlsci/osc` Fork as Custom Server

Update the code in `apps/osc/src/osc.erl` to add the OSC addresses you want to
support (which will require creating the callback code those addreessese will
need). Update `osc_server:init` to call `osc:add_addresses/0` upon startup.

Create and run a release:

    rebar3 release
    cp -r _build/default/rel/osc INSTALL_DIR
    INSTALL_DIR/osc/bin/osc start
    
You can confirm `osc` is running with:

    INSTALL_DIR/osc/bin/osc ping
    
That should return `pong`.

To connect to the running release and get an interactive Erlang shell:

    INSTALL_DIR/osc/bin/osc attach
    Attaching to /tmp/erl_pipes/osc@MM-MAC-7744/erlang.pipe.1 (^D to exit)

    (osc@nodename)1>

## Resources

* [OSC](https://en.wikipedia.org/wiki/Open_Sound_Control) on WikiPedia
* [Intro to OSC](http://opensoundcontrol.org/introduction-osc)
* Open Sound Control's [original home](https://www.cnmat.berkeley.edu/opensoundcontrol)
* [Controlling Ardour with OSC](https://manual.ardour.org/using-control-surfaces/controlling-ardour-with-osc/)
* [SuperCollider OSC Communication](https://doc.sccode.org/Guides/OSC_communication.html)
* [Overtone OSC source code](https://github.com/overtone/overtone/tree/master/src/overtone/osc)
* [OSC 1.0 Specification](http://opensoundcontrol.org/spec-1_0)


[//]: ---Named-Links---

[logo]: priv/images/logo-v2.png
[logo-large]: priv/images/logo-v2-large.png
[github]: https://github.com/erlsci/osc
[gh-actions-badge]: https://github.com/erlsci/osc/workflows/ci%2Fcd/badge.svg
[gh-actions]: https://github.com/erlsci/osc/actions
[erlang-badge]: https://img.shields.io/badge/erlang-19%20to%2023-blue.svg
[versions]: https://github.com/erlsci/osc/blob/master/.github/workflows/cicd.yml
[github-tag]: https://github.com/erlsci/osc/tags
[github-tag-badge]: https://img.shields.io/github/tag/erlsci/osc.svg
[github-downloads]: https://img.shields.io/github/downloads/erlsci/osc/total.svg
