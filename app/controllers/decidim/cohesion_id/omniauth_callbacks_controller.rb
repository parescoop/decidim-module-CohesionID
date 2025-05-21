# frozen_string_literal: true

module Decidim
  module CohesionId
    class OmniauthCallbacksController < ::Decidim::Devise::OmniauthRegistrationsController
      helper Decidim::CohesionId::Engine.routes.url_helpers
      helper_method :omniauth_registrations_path

      skip_before_action :verify_authenticity_token, only: [:cohesion_id, :failure]
      skip_after_action :verify_same_origin_request, only: [:cohesion_id, :failure]

      def cohesion_id
        session["decidim-cohesion_id.signed_in"] = true
        session["decidim-cohesion_id.tenant"] = tenant.name

        authenticator.validate!

        if user_signed_in?
          authenticator.identify_user!(current_user)

          # Aggiunge l'autorizzazione per l'utente
          return fail_authorize(:identity_bound_to_other_user) unless authorize_user(current_user)

          # Aggiorna le informazioni dell'utente
          authenticator.update_user!(current_user, true)

          # to force remain logged in
          u = current_user
          sign_out(current_user)
          sign_in(u) if u.reload.confirmed?
          if !isnt_cie_or_cns? && !u.confirmed?
            flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
          else
            flash[:notice] = t("authorizations.create.success", scope: "decidim.cohesion_id.verification")
          end

          Decidim::CohesionId::CohesionIdJob.perform_later(current_user)
          return redirect_to(stored_location_for(resource || :user) || decidim.root_path)
        end

        # Normale richiesta di autorizzazione, procede con la logica di Decidim
        send(:create)

      rescue Decidim::CohesionId::Authentication::ValidationError => e
        fail_authorize(e.validation_key)
      rescue Decidim::CohesionId::Authentication::IdentityBoundToOtherUserError
        fail_authorize(:identity_bound_to_other_user)
      rescue Decidim::CohesionId::Authentication::AuthorizationBoundToOtherUserError
        fail_authorize(:authorization_bound_to_other_user)
      end

      def create
        form_params = user_params_from_oauth_hash || params.require(:user).permit!
        form_params.merge!(params.require(:user).permit!) if params.dig(:user).present?
        invitation_token = params['invitation_token'] rescue ''

        verified_e = verified_email

        # nel caso la form di integrazione dati viene presentata
        invited_user = nil
        if invitation_token.present?
          invited_user = resource_class.find_by_invitation_token(invitation_token, true)
          invited_user.nickname = nil # Forzo nickname a nil per invalidare il valore normalizzato di Decidim di default
          form_params[:name] = params.dig(:user, :name).present? ? params.dig(:user, :name) : invited_user.name
          @form = form(OmniauthCohesionIdRegistrationForm).from_params(invited_user.attributes.merge(form_params))
          @form.invitation_token = invitation_token
          @form.email ||= invited_user.email
          verified_e = invited_user.email
        else
          # if isnt_cie_or_cns? && (u = current_organization.users.find_by(email: verified_e))
          #   form_params[:name] = u.name
          #   form_params[:nickname] = u.nickname
          # else
            form_params[:name] = params.dig(:user, :name) if params.dig(:user, :name).present? # && isnt_cie_or_cns?
            form_params[:nickname] = params.dig(:user, :nickname) if params.dig(:user, :nickname).present? # && isnt_cie_or_cns?
          # end
          @form = form(OmniauthCohesionIdRegistrationForm).from_params(form_params)
          @form.email ||= verified_e
          verified_e ||= form_params.dig(:email)
        end

        # Controllo che non esisti un'altro account con la stessa email utilizzata con COHESION_ID
        # in quanto a fine processo all'utente viene aggiornata l'email e il tutto protrebbe essere invalido
        if invited_user.present? && form_params.dig(:raw_data, :info, :email).present? && invited_user.email != form_params.dig(:raw_data, :info, :email) &&
          current_organization.users.where(email: form_params.dig(:raw_data, :info, :email)).where.not(id: invited_user.id).present?
          set_flash_message :alert, :failure, kind: "CohesionID", reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
          return redirect_to after_omniauth_failure_path_for(resource_name)
        end

        existing_identity = Identity.find_by(
          user: current_organization.users,
          provider: @form.provider,
          uid: @form.uid
        )

        CreateOmniauthCohesionIdRegistration.call(@form, @form.email || verified_e) do
          on(:ok) do |user|
            # Se l'identità COHESION_ID è già utilizzata da un altro account
            if invited_user.present? && invited_user.email != user.email
              set_flash_message :alert, :failure, kind: "CohesionID", reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
              return redirect_to after_omniauth_failure_path_for(resource_name)
            end

            # match l'utente dell'invitation token passato come relay_state in COHESION_ID Strategy,
            # associo l'identity COHESION_ID all'utente creato nell'invitation e aggiorno l'email dell'utente con quella dello COHESION_ID.
            if invitation_token.present? && invited_user.present? && invited_user.email == user.email
              # per accettare resource_class.accept_invitation!(devise_parameter_sanitizer.sanitize(:accept_invitation).merge(invitation_token: invitation_token))
              user = resource_class.find_by_invitation_token(invitation_token, true)
              # nuovo utente senza password, fallirebbero le validazioni
              token = ::Devise.friendly_token
              user.password = token
              user.password_confirmation = token
              user.save(validate: false)
              user.accept_invitation!
            end

            if user.active_for_authentication?
              if existing_identity
                Decidim::ActionLogger.log(:login, user, existing_identity, {})
              else
                i = user.identities.find_by(uid: @form.uid) rescue nil
                Decidim::ActionLogger.log(:registration, user, i, {})
              end
              if user.is_a?(::Decidim::User)
                if authorize_user(user)
                  authenticator.update_user!(user)
                  sign_in_and_redirect user, verified_email: verified_e, event: :authentication
                  set_flash_message :notice, :success, kind: "CohesionID"
                else
                  fail_authorize(:authorization_bound_to_other_user)
                end
              end

            else
              expire_data_after_sign_in!
              user.resend_confirmation_instructions unless user.confirmed?
              redirect_to decidim.root_path
              flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
            end
          end

          on(:invalid) do
            set_flash_message :notice, :success, kind: "CohesionID"
            render :new
          end

          on(:error) do |user|
            set_flash_message :alert, :failure, kind: "CohesionID", reason: user.errors.full_messages.try(:first)

            render :new
          end
        end
      end

      def failure
        set_flash_message! :alert, :failure, kind: "CohesionID", reason: failure_message
        redirect_to(after_omniauth_failure_path_for(resource_name)) && return
      end

      # def sign_in_and_redirect(resource_or_scope, *args)
      #
      #
      #   super
      # end

      def first_login_and_not_authorized?(_user)
        false
      end

      protected

      def failure_message
        error = request.respond_to?(:get_header) ? request.get_header("omniauth.error") : request.env["omniauth.error"]
        I18n.exists?(error) || Rails.env.development? ? I18n.t(error) : I18n.t('decidim.cohesion_id.omniauth_callbacks.failure.success_status')
      end

      private

      def authorize_user(user)
        authenticator.authorize_user!(user)
      rescue Decidim::CohesionId::Authentication::AuthorizationBoundToOtherUserError
        nil
      end

      def fail_authorize(failure_message_key = :already_authorized)
        flash[:alert] = t("failure.#{failure_message_key}", scope: "decidim.cohesion_id.omniauth_callbacks")
        redirect_to(stored_location_for(resource || :user) || decidim.root_path) && return
      end

      def omniauth_registrations_path(resource)
        decidim_cohesion_id.public_send("user_#{current_organization.enabled_omniauth_providers.dig(:cohesion_id, :tenant_name)}_omniauth_create_url")
      end

      def user_params_from_oauth_hash
        authenticator.user_params_from_oauth_hash
      end

      def authenticator
        @authenticator ||= tenant.authenticator_for(
          current_organization,
          oauth_hash
        )
      end

      def tenant
        @tenant ||= begin
                      matches = request.path.match(%r{^/users/auth/([^/]+)/.+})
                      raise "Invalid CohesionID tenant" unless matches

                      name = matches[1]
                      tenant = Decidim::CohesionId.tenants.find { |t| t.name == name }
                      raise "Unkown CohesionID tenant: #{name}" unless tenant

                      tenant
                    end
      end

      def session_prefix
        tenant.name + '_cohesion_id_'
      end

      def verified_email
        authenticator.verified_email
      end

      def oauth_hash
        raw_hash = request.env["omniauth.auth"] || JSON.parse(params.dig(:user, :raw_data))
        return {} unless raw_hash
        raw_hash.try(:[], 'extra').try(:delete, 'response_object')

        raw_hash.deep_symbolize_keys
      end

      def isnt_cie_or_cns?
        oauth_hash.dig(:info, :spidCode).present?
      end
    end
  end
end
