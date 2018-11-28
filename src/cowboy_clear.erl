%% Copyright (c) 2016-2017, Loïc Hoguin <essen@ninenines.eu>
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(cowboy_clear).
-behavior(ranch_protocol).

-export([start_link/4]).
-export([connection_process/5]).
% start the protocol socket from ranch
-spec start_link(ranch:ref(), inet:socket(), module(), cowboy:opts()) -> {ok, pid()}.
start_link(Ref, Socket, Transport, Opts) ->
	Pid = proc_lib:spawn_link(?MODULE, connection_process,
		[self(), Ref, Socket, Transport, Opts]),
	{ok, Pid}.

-spec connection_process(pid(), ranch:ref(), inet:socket(), module(), cowboy:opts()) -> ok.
connection_process(Parent, Ref, Socket, Transport, Opts) ->
	ok = ranch:accept_ack(Ref),
	init(Parent, Ref, Socket, Transport, Opts, cowboy_http).
% use cowboy_http as default protocol
init(Parent, Ref, Socket, Transport, Opts, Protocol) ->
	_ = case maps:get(connection_type, Opts, supervisor) of
		worker -> ok;
		supervisor -> process_flag(trap_exit, true) %% 进程默认处理退出事件
	end,
	Protocol:init(Parent, Ref, Socket, Transport, Opts).
