Class {
	#name : 'BaselineOfECA',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfECA'
}

{ #category : 'baselines' }
BaselineOfECA >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			baseline: 'OSSubprocess'
			with: [ spec repository: 'github://pharo-contributions/OSSubprocess:main/repository' ].
		spec
			baseline: 'NeoJSON'
			with: [ spec repository: 'github://svenvc/NeoJSON/repository' ].
		spec
			package: 'ECA-Core' with: [ spec requires: #( 'OSSubprocess' 'NeoJSON' ) ];
			package: 'ECA-Spec' with: [ spec requires: #( 'ECA-Core' ) ];
			package: 'ECA-Tests' with: [ spec requires: #( 'ECA-Core' ) ].
		spec
			group: 'Core' with: #( 'ECA-Core' );
			group: 'UI' with: #( 'ECA-Spec' );
			group: 'Tests' with: #( 'ECA-Tests' );
			group: 'default' with: #( 'Core' 'UI' 'Tests' ) ]
]
