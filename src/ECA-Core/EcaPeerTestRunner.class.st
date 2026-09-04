"
Runs SUnit suites for EcaPeerServer's /test op and reports results as a
Dictionary ready for JSON encoding:

	tests / passed / failures / errors / skipped — counts
	timeMs — wall-clock suite time
	defects — printStrings of failed/errored cases ('Class>>#testFoo')

runClassNamed: / runPackageNamed: answer nil when the name resolves to
nothing runnable, letting the server answer 404 rather than 500.
"
Class {
	#name : 'EcaPeerTestRunner',
	#superclass : 'Object',
	#classVars : [
		'TimeoutMs'
	],
	#category : 'ECA-Core-Peer',
	#package : 'ECA-Core',
	#tag : 'Peer'
}

{ #category : 'accessing' }
EcaPeerTestRunner class >> timeoutMs [
	^ TimeoutMs ifNil: [ TimeoutMs := 60000 ]
]

{ #category : 'accessing' }
EcaPeerTestRunner class >> timeoutMs: anInteger [
	TimeoutMs := anInteger
]

{ #category : 'running' }
EcaPeerTestRunner class >> runClassNamed: aString [
	| cls |
	cls := Smalltalk globals at: aString asSymbol ifAbsent: [ ^ nil ].
	(cls isBehavior and: [ cls inheritsFrom: TestCase ]) ifFalse: [ ^ nil ].
	^ self reportFor: cls buildSuite
]

{ #category : 'running' }
EcaPeerTestRunner class >> runPackageNamed: aString [
	| package testClasses suite |
	package := self packageOrganizer
		packageNamed: aString
		ifAbsent: [ ^ nil ].
	testClasses := package definedClasses select: [ :each |
		(each inheritsFrom: TestCase) and: [ each isAbstract not ] ].
	testClasses isEmpty ifTrue: [ ^ nil ].
	suite := TestSuite named: aString.
	testClasses do: [ :each | suite addTest: each buildSuite ].
	^ self reportFor: suite
]

{ #category : 'private' }
EcaPeerTestRunner class >> reportFor: aSuite [
	| started result |
	started := Time millisecondClockValue.
	result := aSuite run.
	^ Dictionary new
		at: 'tests' put: result runCount;
		at: 'passed' put: result passed size;
		at: 'failures' put: result failures size;
		at: 'errors' put: result errors size;
		at: 'skipped' put: result skipped size;
		at: 'timeMs' put: Time millisecondClockValue - started;
		at: 'defects' put: ((result failures asOrderedCollection
				, result errors asOrderedCollection)
				collect: [ :each | each printString ]) asArray;
		yourself
]
