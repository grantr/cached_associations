Dir.glob(File.join(File.dirname(__FILE__), 'lib/active_record/cached_associations/*.rb')).each { |f| require f }
require File.join(File.dirname(__FILE__), 'lib/active_record/cached_associations')
ActiveRecord::Base.send(:include, ActiveRecord::CachedAssociations)
