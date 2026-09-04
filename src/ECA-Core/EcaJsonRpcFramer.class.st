"
LSP-style message framing for the ECA protocol:

	Content-Length: <utf-8 byte count>\r\n
	\r\n
	<json payload>

Pure stream codec: fully testable with in-memory binary streams.
"
Class {
	#name : 'EcaJsonRpcFramer',
	#superclass : 'Object',
	#category : 'ECA-Core-Protocol',
	#package : 'ECA-Core',
	#tag : 'Protocol'
}

{ #category : 'writing' }
EcaJsonRpcFramer >> writeMessage: aDictionary on: aBinaryWriteStream [
	| payload |
	payload := (NeoJSONWriter toString: aDictionary) utf8Encoded.
	aBinaryWriteStream
		nextPutAll: ('Content-Length: ' , payload size asString) utf8Encoded;
		nextPutAll: #[ 13 10 13 10 ];
		nextPutAll: payload;
		flush
]

{ #category : 'reading' }
EcaJsonRpcFramer >> readMessageFrom: aBinaryReadStream [
	"Answer the next decoded message Dictionary, or nil on end of stream."

	| contentLength line body |
	contentLength := nil.
	[ line := self readHeaderLineFrom: aBinaryReadStream.
	  line isNil ] whileFalse: [
		line isEmpty ifTrue: [
			contentLength ifNil: [ ^ nil ].
			body := aBinaryReadStream next: contentLength.
			body size < contentLength ifTrue: [ ^ nil ].
			^ NeoJSONReader fromString: body utf8Decoded ].
		(line asLowercase beginsWith: 'content-length:') ifTrue: [
			contentLength := (line copyAfter: $:) trimBoth asInteger ] ].
	^ nil
]

{ #category : 'reading' }
EcaJsonRpcFramer >> readHeaderLineFrom: aBinaryReadStream [
	"Read bytes up to CRLF. Answer the line as a String, or nil at end of stream."

	| bytes byte |
	bytes := OrderedCollection new.
	[ (byte := aBinaryReadStream next) isNil ] whileFalse: [
		byte = 13
			ifTrue: [
				aBinaryReadStream next. "consume LF"
				^ bytes asByteArray utf8Decoded ]
			ifFalse: [ bytes add: byte ] ].
	^ nil
]
