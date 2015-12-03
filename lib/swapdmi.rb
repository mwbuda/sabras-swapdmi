

# framework components establish basic patterns & utility code
#	used by rest of library.
# they are mostly stuff to help API developers
#	API users should NOT generally make direct use of framework stuff
# 
require 'swapdmi/framework/componentIds'
require 'swapdmi/framework/classHierarchy'
require 'swapdmi/framework/config'
require 'swapdmi/framework/hierachicalIndex'
require 'swapdmi/framework/proxy'

# core components are the main components of the library
#	they are the basic building blocks an API user will use
#

# the registry component provides swap-dmi-esque instance lookup
#	for 3rd-party, non-swap-dmi classes
require 'swapdmi/core/registry'

# impls are integration touch points API users configure
#	to work with their remote data sources
require 'swapdmi/core/modelImpl'
require 'swapdmi/core/mergedModelImpl'

# context of use, model, and datasources
#	are components API users configure/extend to implement their own data API
require 'swapdmi/core/contextOfUse'
require 'swapdmi/core/model'
require 'swapdmi/core/dataSource'
require 'swapdmi/core/smartDataSource'

# extension support framework code
require 'swapdmi/framework/extension'


