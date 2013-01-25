class AFNode
	attr_reader :type

	# type : The data type of this 'type' parameter is symbol.
	#				 This describes that this node is AFSwitch or AFHost.
	def initialize type
		@type = type
	end
end
