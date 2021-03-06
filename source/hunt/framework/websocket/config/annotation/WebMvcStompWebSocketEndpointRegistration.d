/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.websocket.config.annotation.WebMvcStompWebSocketEndpointRegistration;

import hunt.framework.websocket.config.annotation.StompWebSocketEndpointRegistration;

import hunt.framework.task.TaskScheduler;

// import hunt.framework.util.LinkedMultiValueMap;
// import hunt.framework.util.MultiValueMap;
// import hunt.framework.util.ObjectUtils;
// import hunt.framework.util.StringUtils;
// import hunt.framework.web.HttpRequestHandler;
import hunt.framework.websocket.WebSocketMessageHandler;
import hunt.framework.websocket.server.WebSocketHttpRequestHandler;
// import hunt.framework.websocket.server.HandshakeHandler;
// import hunt.framework.websocket.server.HandshakeInterceptor;
// import hunt.framework.websocket.server.support.OriginHandshakeInterceptor;
// import hunt.framework.websocket.sockjs.SockJsService;
// import hunt.framework.websocket.sockjs.support.SockJsHttpRequestHandler;
// import hunt.framework.websocket.sockjs.transport.handler.WebSocketTransportHandler;

import hunt.collection;
import hunt.Exceptions;
import hunt.logging;
import hunt.http.server.WebSocketHandler;

import std.array;

/**
 * An abstract base class for configuring STOMP over WebSocket/SockJS endpoints.
 *
 * @author Rossen Stoyanchev
 * @since 4.0
 */
class WebMvcStompWebSocketEndpointRegistration : StompWebSocketEndpointRegistration {

	private string[] paths;

	private WebSocketMessageHandler webSocketHandler;

	private TaskScheduler sockJsTaskScheduler;
	
	// private HandshakeHandler handshakeHandler;

	// private HandshakeInterceptor[] interceptors;

	private string[] allowedOrigins;

	
	// private SockJsServiceRegistration registration;


	this(string[] paths, WebSocketMessageHandler webSocketHandler, TaskScheduler sockJsTaskScheduler) {
		assert(!paths.empty(), "No paths specified");
		assert(webSocketHandler, "WebSocketHandler must not be null");

		this.paths = paths;
		this.webSocketHandler = webSocketHandler;
		this.sockJsTaskScheduler = sockJsTaskScheduler;
	}

	string[] getPaths() {
		return paths;
	}

	// override
	// StompWebSocketEndpointRegistration setHandshakeHandler(HandshakeHandler handshakeHandler) {
	// 	this.handshakeHandler = handshakeHandler;
	// 	return this;
	// }

	// override
	// StompWebSocketEndpointRegistration addInterceptors(HandshakeInterceptor[] interceptors... ) {
	// 	if (!ObjectUtils.isEmpty(interceptors)) {
	// 		this.interceptors.addAll(Arrays.asList(interceptors));
	// 	}
	// 	return this;
	// }

	override
	StompWebSocketEndpointRegistration setAllowedOrigins(string[] allowedOrigins... ) {
		this.allowedOrigins = [];
		if (!allowedOrigins.empty()) {
			this.allowedOrigins = allowedOrigins.dup;
		}
		return this;
	}

	// override
	// SockJsServiceRegistration withSockJS() {
	// 	// this.registration = new SockJsServiceRegistration();
	// 	// this.registration.setTaskScheduler(this.sockJsTaskScheduler);
	// 	// HandshakeInterceptor[] interceptors = getInterceptors();
	// 	// if (interceptors.length > 0) {
	// 	// 	this.registration.setInterceptors(interceptors);
	// 	// }
	// 	// if (this.handshakeHandler !is null) {
	// 	// 	WebSocketTransportHandler handler = new WebSocketTransportHandler(this.handshakeHandler);
	// 	// 	this.registration.setTransportHandlerOverrides(handler);
	// 	// }
	// 	// if (!this.allowedOrigins.isEmpty()) {
	// 	// 	this.registration.setAllowedOrigins(StringUtils.toStringArray(this.allowedOrigins));
	// 	// }
	// 	// return this.registration;
	// 	implementationMissing(false);
	// 	return null;
	// }

	// protected HandshakeInterceptor[] getInterceptors() {
	// 	List!(HandshakeInterceptor) interceptors = new ArrayList<>(this.interceptors.size() + 1);
	// 	interceptors.addAll(this.interceptors);
	// 	interceptors.add(new OriginHandshakeInterceptor(this.allowedOrigins));
	// 	return interceptors.toArray(new HandshakeInterceptor[0]);
	// }

	Map!(string, WebSocketHandler) getMappings(){
		Map!(string, WebSocketHandler) mappings = new LinkedHashMap!(string, WebSocketHandler)();
		foreach (string path ; this.paths) {
			auto handler = new WebSocketHttpRequestHandler(this.webSocketHandler);
			mappings.put(path, handler);
		}
		return mappings;
	}

	// final MultiValueMap!(WebSocketMessageHandler, string) getMappings() {
	// 	MultiValueMap!(WebSocketMessageHandler, string) mappings = new LinkedMultiValueMap!(WebSocketMessageHandler, string)();
	// 	// if (this.registration !is null) {
	// 	// 	SockJsService sockJsService = this.registration.getSockJsService();
	// 	// 	for (string path : this.paths) {
	// 	// 		string pattern = (path.endsWith("/") ? path ~ "**" : path ~ "/**");
	// 	// 		SockJsHttpRequestHandler handler = new SockJsHttpRequestHandler(sockJsService, this.webSocketHandler);
	// 	// 		mappings.add(handler, pattern);
	// 	// 	}
	// 	// }
	// 	// else 
	// 	{
	// 		// TODO: Tasks pending completion -@zxp at 10/27/2018, 10:56:17 AM
	// 		// 
	// 		foreach (string path ; this.paths) {
	// 			// WebSocketHttpRequestHandler handler;
	// 			// if (this.handshakeHandler !is null) {
	// 			// 	handler = new WebSocketHttpRequestHandler(this.webSocketHandler, this.handshakeHandler);
	// 			// }
	// 			// else 
	// 			// {
	// 				// handler = new WebSocketHttpRequestHandler(this.webSocketHandler);
	// 			// }
	// 			// HandshakeInterceptor[] interceptors = getInterceptors();
	// 			// if (interceptors.length > 0) {
	// 			// 	handler.setHandshakeInterceptors(interceptors);
	// 			// }
	// 			trace("mapping: ", path);
	// 			mappings.add(new class WebSocketHandler {

	// 				override void onConnect(WebSocketConnection webSocketConnection) {
	// 					// onUpgrade(webSocketConnection);
	// 				}

	// 				override void onFrame(Frame frame, WebSocketConnection connection) {
	// 					// this.outer.onFrame(frame, connection);
	// 				}

	// 				override void onError(Exception t, WebSocketConnection connection) {
	// 					// this.outer.onError(t, connection);
	// 				}
	// 			}, path);
	// 		}
	// 	}
	// 	return mappings;
	// }

}
