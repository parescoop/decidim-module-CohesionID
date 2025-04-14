module Decidim
  class User

    def must_log_with_cohesion_id?
      identities.map(&:provider).include?(organization.enabled_omniauth_providers.dig(:cohesion_id, :tenant_name))
    end

    # per disabilatare il recupera password se in precedenza hai fatto l'accesso con CohesionID
    def send_reset_password_instructions
      errors.add(:email, :cant_recover_password_due_cohesion_id) unless !self.must_log_with_cohesion_id?
      super
    end

    def unauthenticated_message
      must_log_with_cohesion_id? ? :invalid_due_cohesion_id : :invalid
    end
  end
end