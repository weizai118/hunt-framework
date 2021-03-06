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

module hunt.framework.websocket.messaging.WebSocketStompClient;

// import java.io.IOException;
// import java.net.URI;
// import java.nio.ByteBuffer;
// import java.util.ArrayList;
// import java.util.Collections;
// import java.util.List;
// import java.util.concurrent.ScheduledFuture;


// import hunt.util.SmartLifecycle;
// import hunt.framework.application.SmartLifecycle;

// import hunt.stomp.Message;
// import hunt.stomp.simp.stomp.BufferingStompDecoder;
// import hunt.stomp.simp.stomp.ConnectionHandlingStompSession;
// import hunt.stomp.simp.stomp.StompClientSupport;
// import hunt.stomp.simp.stomp.StompDecoder;
// import hunt.stomp.simp.stomp.StompEncoder;
// import hunt.stomp.simp.stomp.StompHeaderAccessor;
// import hunt.stomp.simp.stomp.StompHeaders;
// import hunt.stomp.simp.stomp.StompSession;
// import hunt.stomp.simp.stomp.StompSessionHandler;
// import hunt.stomp.support.MessageHeaderAccessor;
// import hunt.stomp.tcp.TcpConnection;
// import hunt.stomp.tcp.TcpConnectionHandler;
// import hunt.framework.task.TaskScheduler;

// import hunt.framework.util.MimeTypeUtils;
// import hunt.framework.util.concurrent.ListenableFuture;
// import hunt.framework.util.concurrent.ListenableFutureCallback;
// import hunt.framework.util.concurrent.SettableListenableFuture;
// import hunt.framework.websocket.BinaryMessage;
// import hunt.http.codec.websocket.model.CloseStatus;
// import hunt.framework.websocket.TextMessage;
// import hunt.http.server.WebSocketHandler;
// import hunt.framework.websocket.WebSocketHttpHeaders;
// import hunt.framework.websocket.WebSocketMessage;
// import hunt.framework.websocket.WebSocketSession;
// import hunt.framework.websocket.client.WebSocketClient;
// import hunt.framework.websocket.sockjs.transport.SockJsSession;
// import hunt.framework.web.util.UriComponentsBuilder;

// /**
//  * A STOMP over WebSocket client that connects using an implementation of
//  * {@link hunt.framework.websocket.client.WebSocketClient WebSocketClient}
//  * including {@link hunt.framework.websocket.sockjs.client.SockJsClient
//  * SockJsClient}.
//  *
//  * @author Rossen Stoyanchev
//  * @since 4.2
//  */
// class WebSocketStompClient extends StompClientSupport implements SmartLifecycle {



//     private final WebSocketClient webSocketClient;

//     private int inboundMessageSizeLimit = 64 * 1024;

//     private bool autoStartup = true;

//     private int phase = DEFAULT_PHASE;

//     private bool running = false;


//     /**
//      * Class constructor. Sets {@link #setDefaultHeartbeat} to "0,0" but will
//      * reset it back to the preferred "10000,10000" when a
//      * {@link #setTaskScheduler} is configured.
//      * @param webSocketClient the WebSocket client to connect with
//      */
//     WebSocketStompClient(WebSocketClient webSocketClient) {
//         assert(webSocketClient, "WebSocketClient is required");
//         this.webSocketClient = webSocketClient;
//         setDefaultHeartbeat(new long[] {0, 0});
//     }


//     /**
//      * Return the configured WebSocketClient.
//      */
//     WebSocketClient getWebSocketClient() {
//         return this.webSocketClient;
//     }

//     /**
//      * {@inheritDoc}
//      * <p>Also automatically sets the {@link #setDefaultHeartbeat defaultHeartbeat}
//      * property to "10000,10000" if it is currently set to "0,0".
//      */
//     override
//     void setTaskScheduler(TaskScheduler taskScheduler) {
//         if (!isDefaultHeartbeatEnabled()) {
//             setDefaultHeartbeat(new long[] {10000, 10000});
//         }
//         super.setTaskScheduler(taskScheduler);
//     }

//     /**
//      * Configure the maximum size allowed for inbound STOMP message.
//      * Since a STOMP message can be received in multiple WebSocket messages,
//      * buffering may be required and this property determines the maximum buffer
//      * size per message.
//      * <p>By default this is set to 64 * 1024 (64K).
//      */
//     void setInboundMessageSizeLimit(int inboundMessageSizeLimit) {
//         this.inboundMessageSizeLimit = inboundMessageSizeLimit;
//     }

//     /**
//      * Get the configured inbound message buffer size in bytes.
//      */
//     int getInboundMessageSizeLimit() {
//         return this.inboundMessageSizeLimit;
//     }

//     /**
//      * Set whether to auto-start the contained WebSocketClient when the Spring
//      * context has been refreshed.
//      * <p>Default is "true".
//      */
//     void setAutoStartup(boolautoStartup) {
//         this.autoStartup = autoStartup;
//     }

//     /**
//      * Return the value for the 'autoStartup' property. If "true", this client
//      * will automatically start and stop the contained WebSocketClient.
//      */
//     override
//     boolisAutoStartup() {
//         return this.autoStartup;
//     }

//     /**
//      * Specify the phase in which the WebSocket client should be started and
//      * subsequently closed. The startup order proceeds from lowest to highest,
//      * and the shutdown order is the reverse of that.
//      * <p>By default this is Integer.MAX_VALUE meaning that the WebSocket client
//      * is started as late as possible and stopped as soon as possible.
//      */
//     void setPhase(int phase) {
//         this.phase = phase;
//     }

//     /**
//      * Return the configured phase.
//      */
//     override
//     int getPhase() {
//         return this.phase;
//     }


//     override
//     void start() {
//         if (!isRunning()) {
//             this.running = true;
//             if (getWebSocketClient() instanceof Lifecycle) {
//                 ((Lifecycle) getWebSocketClient()).start();
//             }
//         }

//     }

//     override
//     void stop() {
//         if (isRunning()) {
//             this.running = false;
//             if (getWebSocketClient() instanceof Lifecycle) {
//                 ((Lifecycle) getWebSocketClient()).stop();
//             }
//         }
//     }

//     override
//     boolisRunning() {
//         return this.running;
//     }


//     /**
//      * Connect to the given WebSocket URL and notify the given
//      * {@link hunt.stomp.simp.stomp.StompSessionHandler}
//      * when connected on the STOMP level after the CONNECTED frame is received.
//      * @param url the url to connect to
//      * @param handler the session handler
//      * @param uriVars the URI variables to expand into the URL
//      * @return a ListenableFuture for access to the session when ready for use
//      */
//     ListenableFuture!(StompSession) connect(string url, StompSessionHandler handler, Object... uriVars) {
//         return connect(url, null, handler, uriVars);
//     }

//     /**
//      * An overloaded version of
//      * {@link #connect(string, StompSessionHandler, Object...)} that also
//      * accepts {@link WebSocketHttpHeaders} to use for the WebSocket handshake.
//      * @param url the url to connect to
//      * @param handshakeHeaders the headers for the WebSocket handshake
//      * @param handler the session handler
//      * @param uriVariables the URI variables to expand into the URL
//      * @return a ListenableFuture for access to the session when ready for use
//      */
//     ListenableFuture!(StompSession) connect(string url, WebSocketHttpHeaders handshakeHeaders,
//             StompSessionHandler handler, Object... uriVariables) {

//         return connect(url, handshakeHeaders, null, handler, uriVariables);
//     }

//     /**
//      * An overloaded version of
//      * {@link #connect(string, StompSessionHandler, Object...)} that also accepts
//      * {@link WebSocketHttpHeaders} to use for the WebSocket handshake and
//      * {@link StompHeaders} for the STOMP CONNECT frame.
//      * @param url the url to connect to
//      * @param handshakeHeaders headers for the WebSocket handshake
//      * @param connectHeaders headers for the STOMP CONNECT frame
//      * @param handler the session handler
//      * @param uriVariables the URI variables to expand into the URL
//      * @return a ListenableFuture for access to the session when ready for use
//      */
//     ListenableFuture!(StompSession) connect(string url, WebSocketHttpHeaders handshakeHeaders,
//             StompHeaders connectHeaders, StompSessionHandler handler, Object... uriVariables) {

//         assert(url, "'url' must not be null");
//         URI uri = UriComponentsBuilder.fromUriString(url).buildAndExpand(uriVariables).encode().toUri();
//         return connect(uri, handshakeHeaders, connectHeaders, handler);
//     }

//     /**
//      * An overloaded version of
//      * {@link #connect(string, WebSocketHttpHeaders, StompSessionHandler, Object...)}
//      * that accepts a fully prepared {@link java.net.URI}.
//      * @param url the url to connect to
//      * @param handshakeHeaders the headers for the WebSocket handshake
//      * @param connectHeaders headers for the STOMP CONNECT frame
//      * @param sessionHandler the STOMP session handler
//      * @return a ListenableFuture for access to the session when ready for use
//      */
//     ListenableFuture!(StompSession) connect(URI url, WebSocketHttpHeaders handshakeHeaders,
//             StompHeaders connectHeaders, StompSessionHandler sessionHandler) {

//         assert(url, "'url' must not be null");
//         ConnectionHandlingStompSession session = createSession(connectHeaders, sessionHandler);
//         WebSocketTcpConnectionHandlerAdapter adapter = new WebSocketTcpConnectionHandlerAdapter(session);
//         getWebSocketClient().doHandshake(adapter, handshakeHeaders, url).addCallback(adapter);
//         return session.getSessionFuture();
//     }

//     override
//     protected StompHeaders processConnectHeaders(StompHeaders connectHeaders) {
//         connectHeaders = super.processConnectHeaders(connectHeaders);
//         if (connectHeaders.isHeartbeatEnabled()) {
//             assert(getTaskScheduler() !is null, "TaskScheduler must be set if heartbeats are enabled");
//         }
//         return connectHeaders;
//     }


//     /**
//      * Adapt WebSocket to the TcpConnectionHandler and TcpConnection contracts.
//      */
//     private class WebSocketTcpConnectionHandlerAdapter implements ListenableFutureCallback!(WebSocketSession),
//             WebSocketHandler, TcpConnection!(byte[]) {

//         private final TcpConnectionHandler!(byte[]) connectionHandler;

//         private final StompWebSocketMessageCodec codec = new StompWebSocketMessageCodec(getInboundMessageSizeLimit());


//         private WebSocketSession session;

//         private long lastReadTime = -1;

//         private long lastWriteTime = -1;

//         private final List<ScheduledFuture<?>> inactivityTasks = new ArrayList<>(2);

//         WebSocketTcpConnectionHandlerAdapter(TcpConnectionHandler!(byte[]) connectionHandler) {
//             assert(connectionHandler, "TcpConnectionHandler must not be null");
//             this.connectionHandler = connectionHandler;
//         }

//         // ListenableFutureCallback implementation: handshake outcome

//         override
//         void onSuccess(WebSocketSession webSocketSession) {
//         }

//         override
//         void onFailure(Throwable ex) {
//             this.connectionHandler.afterConnectFailure(ex);
//         }

//         // WebSocketHandler implementation

//         override
//         void afterConnectionEstablished(WebSocketSession session) {
//             this.session = session;
//             this.connectionHandler.afterConnected(this);
//         }

//         override
//         void handleMessage(WebSocketSession session, WebSocketMessage<?> webSocketMessage) {
//             this.lastReadTime = (this.lastReadTime != -1 ? DateTimeHelper.currentTimeMillis : -1);
//             List!(Message!(byte[])) messages;
//             try {
//                 messages = this.codec.decode(webSocketMessage);
//             }
//             catch (Throwable ex) {
//                 this.connectionHandler.handleFailure(ex);
//                 return;
//             }
//             for (Message!(byte[]) message : messages) {
//                 this.connectionHandler.handleMessage(message);
//             }
//         }

//         override
//         void handleTransportError(WebSocketSession session, Throwable ex) throws Exception {
//             this.connectionHandler.handleFailure(ex);
//         }

//         override
//         void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
//             cancelInactivityTasks();
//             this.connectionHandler.afterConnectionClosed();
//         }

//         private void cancelInactivityTasks() {
//             for (ScheduledFuture<?> task : this.inactivityTasks) {
//                 try {
//                     task.cancel(true);
//                 }
//                 catch (Throwable ex) {
//                     // Ignore
//                 }
//             }
//             this.lastReadTime = -1;
//             this.lastWriteTime = -1;
//             this.inactivityTasks.clear();
//         }

//         override
//         boolsupportsPartialMessages() {
//             return false;
//         }

//         // TcpConnection implementation

//         override
//         ListenableFuture!(Void) send(Message!(byte[]) message) {
//             updateLastWriteTime();
//             SettableListenableFuture!(Void) future = new SettableListenableFuture<>();
//             try {
//                 WebSocketSession session = this.session;
//                 assert(session !is null, "No WebSocketSession available");
//                 session.sendMessage(this.codec.encode(message, session.getClass()));
//                 future.set(null);
//             }
//             catch (Throwable ex) {
//                 future.setException(ex);
//             }
//             finally {
//                 updateLastWriteTime();
//             }
//             return future;
//         }

//         private void updateLastWriteTime() {
//             long lastWriteTime = this.lastWriteTime;
//             if (lastWriteTime != -1) {
//                 this.lastWriteTime = DateTimeHelper.currentTimeMillis();
//             }
//         }

//         override
//         void onReadInactivity(final Runnable runnable, final long duration) {
//             assert(getTaskScheduler() !is null, "No TaskScheduler configured");
//             this.lastReadTime = DateTimeHelper.currentTimeMillis();
//             this.inactivityTasks.add(getTaskScheduler().scheduleWithFixedDelay(() -> {
//                 if (DateTimeHelper.currentTimeMillis - this.lastReadTime > duration) {
//                     try {
//                         runnable.run();
//                     }
//                     catch (Throwable ex) {
//                         version(HUNT_DEBUG) {
//                             trace("ReadInactivityTask failure", ex);
//                         }
//                     }
//                 }
//             }, duration / 2));
//         }

//         override
//         void onWriteInactivity(final Runnable runnable, final long duration) {
//             assert(getTaskScheduler() !is null, "No TaskScheduler configured");
//             this.lastWriteTime = DateTimeHelper.currentTimeMillis();
//             this.inactivityTasks.add(getTaskScheduler().scheduleWithFixedDelay(() -> {
//                 if (DateTimeHelper.currentTimeMillis - this.lastWriteTime > duration) {
//                     try {
//                         runnable.run();
//                     }
//                     catch (Throwable ex) {
//                         version(HUNT_DEBUG) {
//                             trace("WriteInactivityTask failure", ex);
//                         }
//                     }
//                 }
//             }, duration / 2));
//         }

//         override
//         void close() {
//             WebSocketSession session = this.session;
//             if (session !is null) {
//                 try {
//                     session.close();
//                 }
//                 catch (IOException ex) {
//                     version(HUNT_DEBUG) {
//                         trace("Failed to close session: " ~ session.getId(), ex);
//                     }
//                 }
//             }
//         }
//     }


// }


// /**
//     * Encode and decode STOMP WebSocket messages.
//     */
// private class StompWebSocketMessageCodec {

//     private static final StompEncoder ENCODER = new StompEncoder();

//     private static final StompDecoder DECODER = new StompDecoder();

//     private final BufferingStompDecoder bufferingDecoder;

//     StompWebSocketMessageCodec(int messageSizeLimit) {
//         this.bufferingDecoder = new BufferingStompDecoder(DECODER, messageSizeLimit);
//     }

//     List!(Message!(byte[])) decode(WebSocketMessage<?> webSocketMessage) {
//         List!(Message!(byte[])) result = Collections.emptyList();
//         ByteBuffer byteBuffer;
//         if (webSocketMessage instanceof TextMessage) {
//             byteBuffer = ByteBuffer.wrap(((TextMessage) webSocketMessage).asBytes());
//         }
//         else if (webSocketMessage instanceof BinaryMessage) {
//             byteBuffer = ((BinaryMessage) webSocketMessage).getPayload();
//     	}
// 		else {
// 			return result;
// 		}
// 		result = this.bufferingDecoder.decode(byteBuffer);
// 		if (result.isEmpty()) {
// 			version(HUNT_DEBUG) {
// 				trace("Incomplete STOMP frame content received, bufferSize=" ~
// 						this.bufferingDecoder.getBufferSize() ~ ", bufferSizeLimit=" ~
// 						this.bufferingDecoder.getBufferSizeLimit() ~ ".");
// 			}
// 		}
// 		return result;
// 	}

// 	WebSocketMessage<?> encode(Message!(byte[]) message, Class<? extends WebSocketSession> sessionType) {
// 		StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
// 		assert(accessor, "No StompHeaderAccessor available");
// 		byte[] payload = message.getPayload();
// 		byte[] bytes = ENCODER.encode(accessor.getMessageHeaders(), payload);

// 		booluseBinary = (payload.length > 0  &&
// 				!(SockJsSession.class.isAssignableFrom(sessionType)) &&
// 				MimeTypeUtils.APPLICATION_OCTET_STREAM.isCompatibleWith(accessor.getContentType()));

// 		return (useBinary ? new BinaryMessage(bytes) : new TextMessage(bytes));
// 	}
// }
