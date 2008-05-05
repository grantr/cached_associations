module ActiveRecord
  module Associations
    class BelongsToCachedPolymorphicAssociation < BelongsToPolymorphicAssociation
      def find_target
        super
      end

      def fetch_id_cache
      end

      def set_id_cache(id, type)
      end

      def id_cache_key
      end
    end
  end
end
