/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.application.application;

import collie.codec.http.server.websocket;
import collie.buffer;
import collie.codec.http.server;
import collie.codec.http;
import collie.bootstrap.serversslconfig;
import collie.utils.exception;

public import collie.socket.eventloop;
public import collie.socket.eventloopgroup;

public import std.socket;
public import std.experimental.logger;
public import std.file;

import std.string;
import std.conv;
import std.stdio;
import std.uni;
import std.path;
import std.parallelism;
import std.exception;

import hunt.init;
import hunt.routing;
import hunt.application.dispatcher;

public import hunt.http;
public import hunt.view;
public import hunt.i18n;
public import hunt.cache;
public import hunt.utils.path;
public import hunt.application.config;
public import hunt.application.middleware;

public import conRedis = hunt.storage.driver.redis;
public import conMemcache = hunt.storage.driver.memcache;

abstract class WebSocketFactory
{
    IWebSocket newWebSocket(const HTTPMessage header);
}


final class Application
{
    static @property getInstance()
    {
        if(_app is null)
        {
            _app = new Application();
        }
        return _app;
    }

    Address binded(){return addr;}

    /**
     Add a Router rule
     Params:
     method =  the HTTP method. 
     path   =  the request path.
     handle =  the delegate that handle the request.
     group  =  the rule's domain group.
     */
    auto addRoute(string method, string path, HandleFunction handle, string group = DEFAULT_ROUTE_GROUP)
    {
        this._dispatcher.router.addRoute(method, path, handle, group);

        return this;
    }

    // enable i18n
    auto enableLocale(string resPath = buildPath(DEFAULT_RESOURCE_PATH, "lang"), string defaultLocale = "en-us")
    {
        auto i18n = I18n.instance();

        i18n.loadLangResources(resPath);
        i18n.defaultLocale = defaultLocale;

        return this;
    }

    void setWebSocketFactory(WebSocketFactory webfactory)
    {
        _wfactory = webfactory;
    }

    version(NO_TASKPOOL){} else {
        @property TaskPool taskPool(){return _tpool;}
    }

    /// get the router.
    @property router()
    {
        return this._dispatcher.router();
    }

    @property server(){return _server;}

    @property mainLoop(){return _server.eventLoop;}

    @property loopGroup(){return _server.group;}

    @property appConfig(){return Config.app;}

    void setCreateBuffer(CreatorBuffer cbuffer)
    {
        if(cbuffer)
            _cbuffer = cbuffer;
    }

    void setRedis(AppConfig.RedisConf conf)
    {
        version(USE_REDIS){
            if(conf.enabled == true && conf.host && conf.port)
            {
                //writeln(conf);
                conRedis.setDefaultHost(conf.host,conf.port);    
                //cache.driver.setDefaultHost(conf.host,conf.port);    
            }
        }
    }

    void setMemcache(AppConfig.MemcacheConf conf)
    {
        version(USE_MEMCACHE){
            if(conf.enabled == true){
                writeln(conf);
                auto tmp1 = split(conf.servers,","); 
                auto tmp2 = split(tmp1[0],":"); 
                if(tmp2[0] && tmp2[1]){
                    conMemcache.setDefaultHost(tmp2[0],tmp2[1].to!ushort);
                    //cache.driver.setDefaultHost(tmp2[0],tmp2[1].to!ushort);
                }
            }
        }
    }

    private void initDb(AppConfig.DBConfig conf)
    {
        version (WITH_ENTITY) {
            trace("conf..", conf);
            if(conf.url == "")return;
            import std.string;
            import hunt.utils.url;
            import std.conv;
            import hunt.application.model;
            URL url = conf.url.parseURL();
            url.queryArr["user"] = url.user;
            url.queryArr["password"] = url.pass;
            trace("driver:", url.scheme, " hosturl ", url.toString()," user:",url.user, " pwd:", url.pass, "queryarr", url.queryArr);
            initDB(url.scheme, url.scheme~"://" ~url.host ~":" ~to!string(url.port) ~url.path~"?"~url.query,url.queryArr);
        }
    }

    private void initCache(AppConfig.CacheConf config)
    {
        _cache = new Cache(config.storage);
        _cache.setPrefix(config.prefix);
        _cache.setExpire(config.expire);
    }
    
    private void initSession(AppConfig.SessionConf config)
    {
        _session = new Session(config.storage);
        _session.setPrefix(config.prefix);
        _session.setPath(config.path);
        _session.setExpire(config.expire);
    }

    Cache cache()
    {
        return _cache;
    }

	Session session()
	{
		return _session;
	}

    /**
      Start the HTTPServer server , and block current thread.
     */
     void run()
	{
		setConfig(Config.app);
		start();
	}

	void setConfig(AppConfig config)
	{
		setLogConfig(config.log);
		upConfig(config);
		initDb(config.database);
		setRedis(config.redis);
		setMemcache(config.memcache);
		initCache(config.cache);
		initSession(config.session);
	}

	void start()
	{
		writeln("Try to open http://",addr.toString(),"/");
		_server.start();
	}

    /**
      Stop the server.
     */
    void stop()
    {
        _server.stop();
    }
    private:
    RequestHandler newHandler(RequestHandler handler,HTTPMessage msg){
        if(!msg.upgraded)
        {
            return new Request(_cbuffer,&handleRequest,_maxBodySize);
        }
        else if(_wfactory)
        {
            return _wfactory.newWebSocket(msg);
        }

        return null;
    }

    Buffer defaultBuffer(HTTPMessage msg) nothrow
    {
        try{
            import std.experimental.allocator.gc_allocator;
            import collie.buffer.ubytebuffer;
            if(msg.chunked == false)
            {
                string contign = msg.getHeaders.getSingleOrEmpty(HTTPHeaderCode.CONTENT_LENGTH);
                if(contign.length > 0)
                {
                    import std.conv;
                    uint len = 0;
                    collectException(to!(uint)(contign),len);
                    if(len > _maxBodySize)
                        return null;
                }
            }

            return new UbyteBuffer!ubyte();
        }
        catch(Exception e)
        {
            showException(e);
            return null;
        }
    }

    void handleRequest(Request req) nothrow
    {
        this._dispatcher.dispatch(req);
    }

    private:
    void upConfig(AppConfig conf)
    {
        _maxBodySize = conf.upload.maxSize;
        version(NO_TASKPOOL)
        {
            // NOTHING
        }
        else
        {
            _tpool = new TaskPool(conf.http.workerThreads);
            _tpool.isDaemon = true;
        }

        HTTPServerOptions option = new HTTPServerOptions();
        option.maxHeaderSize = conf.http.maxHeaderSize;
        //option.listenBacklog = conf.http.listenBacklog;

        version(NO_TASKPOOL)
        {
            option.threads = conf.http.ioThreads + conf.http.workerThreads;
        }
        else
        {
            option.threads = conf.http.ioThreads;
        }

        option.timeOut = conf.http.keepAliveTimeOut;
        option.handlerFactories.insertBack(&newHandler);
        _server = new HttpServer(option);
        addr = parseAddress(conf.http.address,conf.http.port);
        // foreach(Address addr; conf.bindAddress)
        // {
        HTTPServerOptions.IPConfig ipconf;
        ipconf.address = addr;
        //ipconf.fastOpenQueueSize = conf.fastOpenQueueSize;
        //ipconf.enableTCPFastOpen = (conf.fastOpenQueueSize > 0);

        _server.addBind(ipconf);
        // }

        //if(conf.webSocketFactory)
        //    _wfactory = conf.webSocketFactory;

        trace(conf.route.groups);

        this._dispatcher.setWorkers(_tpool);
        // init dispatcer and routes
        if (conf.route.groups)
        {
            import std.array : split;
            import std.string : strip;

            string[] groupConfig;

            foreach (v; split(conf.route.groups, ','))
            {
                groupConfig = split(v, ":");

                if (groupConfig.length == 3 || groupConfig.length == 4)
                {
                    string value = groupConfig[2];

                    if (groupConfig.length == 4)
                    {
                        if (std.conv.to!int(groupConfig[3]) > 0)
                        {
                            value ~= groupConfig[3];
                        }
                    }

                    this._dispatcher.addRouteGroup(strip(groupConfig[0]), strip(groupConfig[1]), strip(value));

                    continue;
                }

                warningf("Group config format error ( %s ).", v);
            }
        }

        this._dispatcher.loadRouteGroups();
    }

    void setLogConfig(ref AppConfig.LogConfig conf)
    {
        switch(conf.level)
        {
            case "all":
                globalLogLevel = LogLevel.all;
                break;
            case "critical":
                globalLogLevel = LogLevel.critical;
                break;
            case "error":
                globalLogLevel = LogLevel.error;
                break;
            case "fatal":
                globalLogLevel = LogLevel.fatal;
                break;
            case "info":
                globalLogLevel = LogLevel.info;
                break;
            case "trace":
                globalLogLevel = LogLevel.trace;
                break;
            case "warning":
                globalLogLevel = LogLevel.warning;
                break;
            case "off":
            default:
                globalLogLevel = LogLevel.off;
                break;
        }

        if(conf.file.length > 0 && conf.path.length > 0)
        {
            import std.path;
            string file = buildPath(conf.path,conf.file);
            sharedLog = new FileLogger(file);
        }
    }

    this()
    {
        _cbuffer = &defaultBuffer;
        this._dispatcher = new Dispatcher();
    }

    __gshared static Application _app;

    private:
    Address addr;
    HttpServer _server;
    WebSocketFactory _wfactory;
    uint _maxBodySize;
    CreatorBuffer _cbuffer;
    Dispatcher _dispatcher;
    __gshared Cache _cache;
	__gshared Session _session;

    version(NO_TASKPOOL)
    {
        // NOTHING TODO
    }
    else
    {
        __gshared TaskPool _tpool;
    }
}
