

module Services
  module ActAsServicesDeleteAudit

    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def act_as_services_delete_audit(options = {})

        class_inheritable_reader :audit_association_model
        class_inheritable_reader :audited_columns

        write_inheritable_attribute :audit_association_model, options[:with_audit_association].blank? ? nil : options[:with_audit_association].to_sym
        write_inheritable_attribute :audited_columns, options[:additional_audited_columns].blank? ? nil : options[:additional_audited_columns].to_a

        has_one :audit, :as => :auditable, :order => "created_at DESC"

        after_destroy :audit_destroy

        include Services::ActAsServicesDeleteAudit::InstanceMethods
      end
    end

    module InstanceMethods

      #Should be reload in model
      def name
        defined?(super) ? super : self.read_attribute(:name) || self.read_attribute(:fullname) || ""
      end

      #Should be reload in model 
      def to_services_attrs
        {}
      end
      
      private

      def audit_destroy
        attr = {}
        attr[:status] = self.errors.empty? ? Audit::Statuses::SUCCESS : Audit::Statuses::FAILED
        attr[:name] = "#{self.name}"
        if attr[:status] == Audit::Statuses::FAILED
          attr[:auditable_attributes] = self.to_services_attrs.merge(self.attributes.slice(*audited_columns))
          attr[:messages] = self.errors.full_messages
        end
        attr[:associations_audits] = self.send(audit_association_model).map(&:audit).compact unless audit_association_model.blank?
        self.create_audit(attr)
      end
    end
  end
end