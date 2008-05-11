module ActiveRecord
  module CachedAssociations

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def belongs_to_cached(association_id, options = {})
        [:finder_sql, :group, :include, :select].each do |option|
          raise "Can't cache associations using :finder_sql, :group, :include, or :select" if options.include?(option)
        end
        reflection = create_belongs_to_reflection(association_id, options)
        
        if reflection.options[:polymorphic]
          association_accessor_methods(reflection, BelongsToCachedPolymorphicAssociation)

          module_eval do
            before_save <<-EOF
              association = instance_variable_get("@#{reflection.name}")
              if association && association.target
                if association.new_record?
                  association.save(true)
                end
                
                if association.updated?
                  self["#{reflection.primary_key_name}"] = association.id
                  self["#{reflection.options[:foreign_type]}"] = association.class.base_class.name.to_s
                  association.set_id_cache(association.id, association.class.base_class.name.to_s)
                end
              end
            EOF
          end
        else
          association_accessor_methods(reflection, BelongsToCachedAssociation)
          association_constructor_method(:build,  reflection, BelongsToCachedAssociation)
          association_constructor_method(:create, reflection, BelongsToCachedAssociation)

          module_eval do
            before_save <<-EOF
              association = instance_variable_get("@#{reflection.name}")
              if !association.nil? 
                if association.new_record?
                  association.save(true)
                end
                
                if association.updated?
                  self["#{reflection.primary_key_name}"] = association.id
                  association.set_id_cache(association.id)
                end
              end            
            EOF
          end
        end

        # Create the callbacks to update counter cache
        if options[:counter_cache]
          cache_column = options[:counter_cache] == true ?
            "#{self.to_s.underscore.pluralize}_count" :
            options[:counter_cache]

          module_eval(
            "after_create '#{reflection.name}.class.increment_counter(\"#{cache_column}\", #{reflection.primary_key_name})" +
            " unless #{reflection.name}.nil?'"
          )

          module_eval(
            "before_destroy '#{reflection.name}.class.decrement_counter(\"#{cache_column}\", #{reflection.primary_key_name})" +
            " unless #{reflection.name}.nil?'"
          )
          
          module_eval(
            "#{reflection.class_name}.send(:attr_readonly,\"#{cache_column}\".intern) if defined?(#{reflection.class_name}) && #{reflection.class_name}.respond_to?(:attr_readonly)"
          )
        end
      end

      def has_many_cached(association_id, options = {}, &extension)
        [:finder_sql, :group, :include, :select].each do |option|
          raise "Can't cache associations using :finder_sql, :group, :include, or :select" if options.include?(option)
        end
        reflection = create_has_many_reflection(association_id, options, &extension)

        configure_dependency_for_has_many(reflection)

        if options[:through]
          collection_reader_method(reflection, HasManyThroughAssociation)
          collection_accessor_methods(reflection, HasManyThroughAssociation, false)
        else
          add_multiple_associated_save_callbacks(reflection.name)
          add_association_callbacks(reflection.name, reflection.options)
          add_cache_expiry_callbacks(reflection.name)
          collection_accessor_methods(reflection, HasManyCachedAssociation)
        end
      end

      def add_cache_expiry_callbacks(association_name)
        %w( after_add after_remove).each do |callback_name|
          full_callback_name = "#{callback_name}_for_#{association_name}"
          callbacks = read_inheritable_attribute(full_callback_name.to_sym)
          callbacks << lambda { |owner, record| owner.send(association_name.to_sym).expire_id_cache }
        end
      end
    end
  end
end
