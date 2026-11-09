

# Aggiunge la destroy delle autorizzazioni

# frozen_string_literal: true

module Decidim
  class DestroyAccount

    def call
      return broadcast(:invalid) unless @form.valid?

      Decidim::User.transaction do
        destroy_user_account!
        destroy_user_authorizations
        destroy_user_identities
        destroy_user_group_memberships
        destroy_follows
        destroy_participatory_space_private_user
        delegate_destroy_to_participatory_spaces
      end

      Rails.logger.info("decidim-module-cohesion_id || Distrutto utente #{current_user.id}: il record sul DB è ancora presente, viene soltanto 'ripulito' dai dati personali.")

      broadcast(:ok)
    end

    private

    def destroy_user_account!
      current_user.invalidate_all_sessions!

      current_user.name = ""
      current_user.nickname = ""
      current_user.email = ""
      current_user.personal_url = ""
      current_user.about = ""
      current_user.notifications_sending_frequency = "none"
      current_user.delete_reason = @form.delete_reason
      current_user.admin = false if current_user.admin?
      current_user.deleted_at = Time.current
      current_user.skip_reconfirmation!
      current_user.avatar.purge
      current_user.save!
    end


    # Rimossa cancellazione
    def destroy_user_authorizations
      name = "#{@form.current_organization.enabled_omniauth_providers.dig(:cohesion_id, :tenant_name)}_identity"
      Decidim::Authorization.where(user: current_user, name: name).destroy_all
    end

  end
end
