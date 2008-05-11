module ActiveRecord
  module CachedAssociations
    class HasManyCachedAssociation < ActiveRecord::Associations::HasManyAssociation
      def find_target
        if association_ids = fetch_id_cache
          records = @reflection.klass.get_caches(association_ids).values
        else
          if records = find(:all)
            set_id_cache(records.collect(&:id))
            records.each { |record| @reflection.klass.set_cache(record.id, record) }
          end
        end

        @reflection.options[:uniq] ? uniq(records) : records
      end

      def fetch_id_cache
        @owner.class.fetch_cache(id_cache_key)
      end

      def set_id_cache(id)
        @owner.class.set_cache(id_cache_key, id)
      end

      def expire_id_cache
        @owner.class.expire_cache(id_cache_key)
      end

      def id_cache_key
        "#{@owner.id}:#{@reflection.name}"
      end
    end
  end
end
