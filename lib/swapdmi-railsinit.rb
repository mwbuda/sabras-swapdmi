
#
# a Ruby on Rails specific initializer.
#	generally, you want to add a new script under Rails config/initializers which and configures the initializer, 
#	and then calls the invoke method
#
# the initilizer follows these conventions:
#	* definition of domain objects & implementations will be under Rails app/models root
#	* initializer will be configured via config/models.yml
#		- 'swapdmi.loadDomainDefinitions': array of domain model definitions library files
#		- 'swapdmi.loadDomainImplementations': array of domain model implemenation files (functors)
#		- 'swapdmi.defaultModelLogicId': default model logic id. this should ALWAYS be provided.
#		- 'swapdmi.setMergeDelegates': key->array hash defining ModelLogicMerge delegates
#

require 'swapdmi-core'

module SwapDmi
class RailsInit

	def self.invoke()
		self.new.invoke
	end

	def invoke()
		cfg = YAML.load_file( Rails.root.join('config','models.yml') )
		cfg[Rails.env]['swapdmi.loadDomainDefinitions'].each {|domainModels| require Rails.root.join('app/models', domainModels) }
		cfg[Rails.env]['swapdmi.loadDomainImplementations'].each {|modelImpl| require Rails.root.join('app/models', modelImpl) }
		SwapDmi::ModelLogic.defineDefault( cfg[Rails.env]['swapdmi.defaultModelLogicId'].to_sym )
		cfg[Rails.env]['swapdmi.setMergeDelegates'].each {|mk, delegates| SwapDmi.ModelLogic.instance(mk).delegateTo(*delegates) }
	end

end end

