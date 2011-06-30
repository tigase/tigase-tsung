%%%-------------------------------------------------------------------
%%% File    : ts_test_recorder.erl
%%% Author  : Nicolas Niclausse <nicolas@niclux.org>
%%% Description :
%%%
%%% Created : 20 Mar 2005 by Nicolas Niclausse <nicolas@niclux.org>
%%%-------------------------------------------------------------------
-module(ts_test_config).

-compile(export_all).

-include("ts_profile.hrl").
-include("ts_config.hrl").
-include_lib("eunit/include/eunit.hrl").
-include("xmerl.hrl").

test()->
    ok.
read_config_http_test() ->
    myset_env(),
    ?assertMatch({ok, Config}, ts_config:read("./examples/http_simple.xml",".")).
read_config_http2_test() ->
    myset_env(),
    ?assertMatch({ok, Config}, ts_config:read("./examples/http_distributed.xml",".")).
read_config_pgsql_test() ->
    myset_env(),
    ?assertMatch({ok, Config}, ts_config:read("./examples/pgsql.xml",".")).
read_config_jabber_test() ->
    myset_env(),
    ts_user_server:start([]),
    ?assertMatch({ok, Config}, ts_config:read("./examples/jabber.xml",".")).

read_config_jabber_muc_test() ->
    myset_env(),
    ts_user_server:start([]),
    ?assertMatch({ok, Config}, ts_config:read("./examples/jabber_muc.xml",".")).

read_config_xmpp_muc_test() ->
    myset_env(),
    ts_user_server:start([]),
    ?assertMatch({ok, Config}, ts_config:read("./src/test/xmpp-muc.xml",".")).

config_get_session_test() ->
    myset_env(),
    ts_user_server:start([]),
    ts_config_server:start_link(["/tmp"]),
    ok = ts_config_server:read_config("./examples/http_setdynvars.xml"),
    {ok, {Session,IP,Server,1,full} }  = ts_config_server:get_next_session("localhost"),
    ?assertEqual(1, Session#session.id).

config_get_session_size_test() ->
    myset_env(),
    {ok, {Session,IP,Server,2,_} }  = ts_config_server:get_next_session("localhost"),
    ?assertEqual(13, Session#session.size).


read_config_badpop_test() ->
    myset_env(),
    ts_user_server:start([]),
    {ok, Config} = ts_config:read("./src/test/badpop.xml","."),
    ?assertMatch({error,[{error,{bad_sum,_,_}}]}, ts_config_server:check_config(Config)).


read_config_thinkfirst_test() ->
    myset_env(),
    ?assertMatch({ok, Config}, ts_config:read("./src/test/thinkfirst.xml",".")).


config_minmax_test() ->
    myset_env(),
    {ok, {Session,IP,Server,3,_} }  = ts_config_server:get_next_session("localhost"),
    Id = Session#session.id,
    ?assertMatch({thinktime,{range,2000,4000}}, ts_config_server:get_req(Id,7)).

config_minmax2_test() ->
    myset_env(),
    {ok, {Session,IP,Server,4,_} }  = ts_config_server:get_next_session("localhost"),
    Id = Session#session.id,
    {thinktime, Req} = ts_config_server:get_req(Id,7),
    Think=ts_client:set_thinktime(Req),
    Resp = receive
         Data-> Data
    end,
    ?assertMatch({timeout,_,end_thinktime}, Resp).

config_thinktime_test() ->
    myset_env(),
    ok = ts_config_server:read_config("./examples/thinks.xml"),
    {ok, {Session,IP,Server,5,_} }  = ts_config_server:get_next_session("localhost"),
    Id = Session#session.id,
    {thinktime, Req=2000} = ts_config_server:get_req(Id,5),
    {thinktime, 2000} = ts_config_server:get_req(Id,7),
    Think=ts_client:set_thinktime(Req),
    Resp = receive
         Data-> Data
    end,
    ?assertMatch({timeout,_,end_thinktime}, Resp).


config_thinktime2_test() ->
    myset_env(),
    ok = ts_config_server:read_config("./examples/thinks2.xml"),
    {ok, {Session,{IP,0},Server,6,none} }  = ts_config_server:get_next_session("localhost"),
    Id = Session#session.id,
    {thinktime, Req} = ts_config_server:get_req(Id,5),
    Ref=ts_client:set_thinktime(Req),
    receive
        {timeout,Ref2,end_thinktime} -> ok
    end,
    random:seed(), % reinit seed for others tests
    ?assertMatch({random,1000}, Req).
read_config_maxusers_test() ->
    myset_env(),
    MaxNumber=10,
    C=lists:map(fun(A)->"client"++integer_to_list(A) end, lists:seq(1,10)),
    ts_config_server:read_config("./src/test/thinkfirst.xml"),
    M = lists:map(fun(X)->
                          {ok,{[{_,Max,_},{_,_,_}],_,_}} = ts_config_server:get_client_config(X),
                          Max
                  end,  C),
    ?assertEqual(lists:sum(M), MaxNumber).

read_config_static_test() ->
    myset_env(),
    C=lists:map(fun(A)->"client"++integer_to_list(A) end, lists:seq(1,10)),
    M = lists:map(fun(X)->
                          {ok,Res,_} = ts_config_server:get_client_config(static,X),
                          ?LOGF("X: ~p~n",[length(Res)],?ERR),
                          length(Res)
                  end,  C),
    ?assertEqual(lists:sum(M) , 4).


cport_list_node_test() ->
    List=['tsung1@toto',
          'tsung3@titi',
          'tsung2@toto',
          'tsung7@titi',
          'tsung6@toto',
          'tsung4@tutu'],
    Rep =  ts_config_server:get_one_node_per_host(List),
    ?assertEqual(['tsung1@toto', 'tsung3@titi', 'tsung4@tutu'], lists:sort(Rep)).


ifalias_test() ->
    Res=ts_ip_scan:get_intf_aliases("lo"),
    ?assertEqual([{127,0,0,1}],Res).

encode_test() ->
    Encoded="ts_encoded_47myfilepath_47toto_47titi_58sdfsdf_45sdfsdf_44aa_47",
    Str="/myfilepath/toto/titi:sdfsdf-sdfsdf,aa/",
    ?assertEqual(Encoded,ts_config_server:encode_filename(Str)).

decode_test() ->
    Encoded="ts_encoded_47myfilepath_47toto_47titi_58sdfsdf_45sdfsdf_44aa_47",
    Str="/myfilepath/toto/titi:sdfsdf-sdfsdf,aa/",
    ?assertEqual(Str,ts_config_server:decode_filename(Encoded)).

concat_atoms_test() ->
    ?assertEqual('helloworld', ts_utils:concat_atoms(['hello','world'])).


int_or_string_test() ->
     ?assertEqual(123, ts_config:getAttr(integer_or_string,[#xmlAttribute{name=to,value="123"}],to)).
int_or_string2_test() ->
    ?assertEqual("%%_toto%%", ts_config:getAttr(integer_or_string,[#xmlAttribute{name=to,value="%%_toto%%"}],to)).
int_test() ->
    ?assertEqual(100, ts_config:getAttr(integer,[#xmlAttribute{name=to,value="100"}],to)).

myset_env()->
    myset_env(0).
myset_env(Level)->
    catch  ts_user_server_sup:start_link() ,
    application:set_env(stdlib,debug_level,Level),
    application:set_env(stdlib,warm_time,1000),
    application:set_env(stdlib,thinktime_value,"5"),
    application:set_env(stdlib,thinktime_override,"false"),
    application:set_env(stdlib,thinktime_random,"false").
