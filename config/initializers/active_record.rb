module ActiveRecord
  module Associations
    class HasManyThroughAssociation < HasManyAssociation

      # TODO - add dependent option support
      def delete_records(records)
        klass = @reflection.through_reflection.klass
        records.each do |associate|
          # klass.delete_all(construct_join_attributes(associate))
          klass.destroy_all(construct_join_attributes(associate))
        end
      end

    end
  end
end
