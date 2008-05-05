module ActiveRecord
  module CachedAssociations
    class BelongsToCachedAssociation < ActiveRecord::Associations::BelongsToAssociation
      def find_target
        if association_id = fetch_id_cache
          @reflection.klass.get_cache(association_id)
        else
          if association = super
            set_id_cache(association.id)
            @reflection.klass.set_cache(association.id, association)
          end
          association
        end
      end

      def fetch_id_cache
        @owner.class.fetch_cache(id_cache_key)
      end

      def set_id_cache(id)
        @owner.class.set_cache(id_cache_key, id)
      end

      def id_cache_key
        "#{@owner.id}:#{@reflection.name}"
      end
    end
  end
end
