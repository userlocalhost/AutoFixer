require 'af-node'

class AFHost < AFNode
	attr_reader :nics

	class NIC
		attr_reader :mac
		attr_reader :ip

		#
		# Create a logical-NIC
		#
		# @param [Trema::Mac] mac
		#		MAC address which is related to this object
		#
		# @param [Trema::IP] ip
		#		IP address which is related to this object
		#
		def initialize mac, ip
			@mac = mac
			@ip = ip
		end

		def set_ip ip
			@ip = ip
		end
	end

	### class methods ###
	@@nodelist = []

	def self.add mac, ip=nil
		afhost = self.find mac
		if ! afhost
			nic = NIC.new mac, ip
			afhost = self.new nic
	
			@@nodelist << afhost
		end

		afhost
	end

	def self.find addr
		@@nodelist.find { |node| node.has? addr }
	end

	def self.select addr
		@@nodelist.select { |node| node.has? addr }
	end
	#####################
	
	def initialize *nics
		@nics = []

		nics.each do |nic|
			@nics << nic
		end
	end

	def set_ip mac, ip
		nic = @nics.find {|x| x.mac == mac}
		if nic
			nic.set_ip ip
		end
	end

	def has? addr
		case addr
			when Trema::Mac
				@nics.any? {|nic| nic.mac == addr}
			when Trema::IP
				@nics.any? {|nic| nic.ip.to_i == addr}
			else
				false
			end
	end
end
