require 'af-node'

# This datastructure describes openflow switch.

class AFSwitch < AFNode

	### class methods ###
	#
	@@nodelist = []

	#
	# Registers an AFSwitch object.
	#
	def self.add dpid
		@@nodelist << self.new( dpid )
	end

	#
	# Get an AFSwitch object, or AFSwitch object that is connected from another object.
	#
	def self.get option
		if option[ :dpid ]
			# Get an AFSwitch object of option[ :dpid ]
			@@nodelist.find { |sw| sw.class == AFSwitch && sw.dpid == option[ :dpid ] }
		elsif option[ :connected_node ]
			# Get an AFSwitch object that connected with option[ :connected_node ]
			@@nodelist.find { |x| x.connected? option[ :connected_node ] }
		end
	end

	#
	# Get an AFSwitch object that connected with detected AFNode
	#
	def self.search_switch node
		@@nodelist.find { |x| x.connected? node }
	end

	def self.dump
		@@nodelist.each do |each|
			each.port.each do |port, node|
				case node
				when AFSwitch
					puts "[AFSwitch.dump] (#{each.dpid}) [port:#{port}] AFSwitch (dpid:#{node.dpid})"
				when AFHost
					puts "[AFSwitch.dump] (#{each.dpid}) [port:#{port}] AFHost (#{node.nics[0].mac})"
				end
			end
		end
	end
	#
	#####################

	### instance methods ###
	#
	attr_reader :dpid
	attr_reader :port

	def initialize( dpid )
		super( :switch )

		@dpid = dpid
		@port = {}
	end

	#
	# Set a AFNode to port
	#
	# @param [AFSwitch, AFHost] node
	#		a node which is connects to this switch
	#
	def set port, node
		if @port[ port ].class != AFSwitch
			@port[ port ] = node
		end
	end

	def get port
		@port[ port ]
	end

	def get_port node
		tuple = @port.find {|p, n| n == node }

		tuple ? tuple[0] : nil
	end

	def connected? node
		@port.any? { |p, n| n == node }
	end
	########################
end
