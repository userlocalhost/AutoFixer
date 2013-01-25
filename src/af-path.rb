# About routing

require 'af-switch'

class AFPath

	@@afpathes = []

	attr_reader :src_host
	attr_reader :dst_host

	class Path
		attr_reader :intermediates

		def initialize intermediates
			@intermediates = intermediates
		end
	end
	
	class Intermediate
		attr_accessor :in_port
		attr_accessor :out_port
		attr_accessor :dpid

		def initialize dpid
			@in_port = nil
			@out_port = nil
			@dpid = dpid
		end
	end

	def initialize src, dst, pathes
		@src_host = src
		@dst_host = dst
		@pathes = pathes
	end

	def get_optimal_path
		# this is temporary processing
		if ! @pathes.empty?
			index = rand(100) % @pathes.length

			@pathes[ index ]
		end
	end

	#
	# class methods
	#
	def self.make_path src_host, dst_host
		if src_host.class == AFHost && dst_host.class == AFHost
			neighbor = find_connected_node src_host

			pathes = make_route( src_host, neighbor, dst_host )
			afpath = AFPath.new( src_host, dst_host, pathes )

			## register ##
			@@afpathes << afpath

			afpath.get_optimal_path
		end
	end

	private
	#
	# This makes route list
	#
	def self.make_route prev_n, curr_n, exit_n, backtrace=[]

		ret = []
		if curr_n.class != AFSwitch

			if curr_n == exit_n
				path = Path.new( Marshal.load( Marshal.dump( backtrace ) ) )

				ret = [ path ]
			end

		elsif ! backtrace.any? { |each| each.dpid == curr_n.dpid }

			# make new Intermediate object
			intermediate = Intermediate.new curr_n.dpid
		
			# set current in_port
			intermediate.in_port = curr_n.get_port prev_n
	
			curr_n.port.each do |port_no, next_n|
				intermediate.out_port = port_no
	
				route = backtrace + [ intermediate ]
	
				ret += make_route curr_n, next_n, exit_n, route
			end
		end

		ret
	end

	# 
	# This returns the AFSwitch which is connected with detected end-point node
	#
	# @param [ AFNode ] porint
	#		This describes start-point
	#
	def self.find_connected_node node
		AFSwitch.get( :connected_node => node)
	end
end
