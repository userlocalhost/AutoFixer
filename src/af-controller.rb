require 'digest/md5'

require 'af-switch'
require 'af-host'
require 'af-path'

class AFController < Controller
	LONG_MAX = ( 1 << 64 ) - 1
	TRANSPORT_MAX = 5

	add_periodic_timer_event :path_traffic_measuring, 10

	def start
		@packet_hash = Hash.new
	end

	def switch_ready dpid
		AFSwitch.add( dpid )
	
		send_discover_frame dpid
	end

	def features_reply dpid, msg
	end

	def packet_in dpid, msg
		switch = AFSwitch.get( :dpid => dpid )
		if ! switch
			puts "(ERROR) [packet_in] dpid=#{dpid} is not initialized"
		end

		if( msg.eth_type == 0xffff )
			from_dpid = get_dpid( msg.macsa, msg.macda )

			switch.set( msg.in_port, AFSwitch.get( :dpid => from_dpid ) )
		elsif( msg.eth_type == 0x0800 )
			# may create 
			src_host = AFHost.add msg.macsa
			dst_host = AFHost.find msg.macda

			# set AFHost object to AFSwitch
			switch.set( msg.in_port, src_host )

			# set network address to AFHost object
			if msg.ipv4?
				src_host.set_ip( msg.macsa, msg.ipv4_saddr )
			elsif msg.arp?
				src_host.set_ip msg.macsa, msg.arp_spa
			end

			# update packet-hash
			md5hash = Digest::MD5.new.update(msg.data).to_s
			if @packet_hash[ md5hash ]
				@packet_hash[ md5hash ] += 1 
			else
				@packet_hash[ md5hash ] = 1
			end

			if dst_host
				path = AFPath.make_path src_host, dst_host

				if path
					path.intermediates.each do |each|
						match = Match.new( :in_port => each.in_port,
														   :dl_src => msg.macsa,
															 :dl_dst => msg.macda )

						send_flow_mod_add( each.dpid,
														   :match => match,
														   :hard_timeout => 60,
														   :actions => ActionOutput.new(:port => each.out_port) )
					end
				end
			else
				# flooding

				if @packet_hash[ md5hash ] < TRANSPORT_MAX
					send_packet_out dpid,
						:packet_in => msg,
						:actions => ActionOutput.new( :port => OFPP_FLOOD )
				end

			end
		end
	end

	private
	def create_discover_frame dpid
		# dpid( 8byte ) + padding( 4byte ) + type( 2byte )
		sprintf( "%016x", dpid & LONG_MAX ) + "00000000ffff"
	end

	def create_payload byte
		'00' * byte
	end

	def send_discover_frame dpid
		send_packet_out dpid,
			:actions => ActionOutput.new( :port => OFPP_FLOOD ),
			:data => [ create_discover_frame( dpid ) + create_payload( 50 ) ].pack( "H*" )
	end

	#
	# Extract dpid from a discover-packet
	#
	def get_dpid macsa, macda
		( macda.to_s.split(':') + macsa.to_s.split(':') )[0..7].join.hex
	end


	#
	# This send features request periodically for measureing path.
	#
	def path_traffic_measuring
	end
end
