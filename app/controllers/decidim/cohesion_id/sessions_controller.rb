require 'decidim/cohesion_id/client'

module Decidim
  module CohesionId
    class SessionsController < ::Decidim::Devise::SessionsController

      def destroy
        return super unless session.delete("decidim-cohesion_id.signed_in")

        tenant_name = session["decidim-cohesion_id.tenant"]
        raise "Unkown CohesionId tenant: #{tenant_name}" unless tenant

        i = current_user.identities.find_by(provider: tenant.name) rescue nil
        Decidim::ActionLogger.log(:logout, current_user, i, {}) if i

        current_user.invalidate_all_sessions!
        Decidim::CohesionId::Client.call(tenant.config, "LogoutSito", session.delete("decidim-#{tenant.name}.id_sessione_sso"), session.delete("decidim-#{tenant.name}.id_sessione_aspnet_sso"))

        sign_out_path = tenant.config.entity_id

        set_flash_message! :notice, :signed_out
        return redirect_to(decidim.new_user_session_path) if current_organization.force_users_to_authenticate_before_access_organization

        redirect_to sign_out_path
      end
      

      def tenant
        @tenant ||= begin
                      name = session.delete("decidim-cohesion_id.tenant")
                      raise "Invalid CohesionId tenant" unless name

                      tenant = Decidim::CohesionId.tenants.find { |t| t.name == name }
                      raise "Unkown CohesionId tenant: #{name}" unless tenant

                      tenant
                    end
      end

    end
  end
end
