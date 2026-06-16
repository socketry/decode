# frozen_string_literal: true

# The context object.
Context = Struct.new(:arguments, keyword_init: true) do
	# Build a context.
	def self.for(arguments)
	end
	
	# The completed words.
	def words
	end
end

module Types
	# The request object.
	Request = Data.define(:arguments) do
		# Build a request.
		def self.for(arguments)
		end
		
		# The completed words.
		def words
		end
	end
end
