# frozen_string_literal: true

module Decidim
  module CohesionId
    class Tenant
      include ActiveSupport::Configurable

      # Il nome che identificata il singolo Tenant. Default: cohesionID
      config_accessor :name, instance_writer: false do
        "cohesionID"
      end

      # Definisce il dominio del tenant
      config_accessor :entity_id

      # Provider WAYF endpoint
      config_accessor :sso_check_url

      # Definisce SSOwebCheckSession
      config_accessor :sso_web_check_session

      config_accessor :id_sito

      # Default: 1 = Accesso con password e PIN o token OTP - SPID Livello 2
      config_accessor :auth_restriction do
        [1]
      end

      config_accessor :url_after_login do
        '/'
      end

      # Default: UType=c = Accesso per soli cittadini, l'autenticazione tramite credenziali Cohesion è disabilitata
      config_accessor :u_type do
        'c'
      end

      # Ad esempio, impostando il parametro come purpose='PG' Cohesion consentirà l'accesso solamente alle persone dotate di SPID Giuridico.
      config_accessor :purpose do
        []
      end

      # Se l'ente è federato in modalità aggregata, sarà necessario inserire il parametro aggregato=1
      config_accessor :aggregato do
        nil
      end

      # Abilita il login tramite il nodo italiano eIDAS specificando se, a valle dell'autenticazione, è necessaria la verifica del Codice Fiscale
      config_accessor :eidas do
        nil
      end

      # Se non specificato, verrà utilizzato il protocollo di default SAML. Impostando il parametro come SpidMode=OIDC verrà utilizzato il nuovo protocollo OpenID Connect
      config_accessor :spid_mode do
        nil
      end

      # Se non specificato, verrà utilizzato il protocollo di default SAML. Impostando il parametro come SpidMode=OIDC verrà utilizzato il nuovo protocollo OpenID Connect
      config_accessor :cie_mode do
        nil
      end

      # Specificando questo parametro, CohesionId effettuerà la richiesta di autenticazione verso le piattaforme nazionali ed europee per conto dell'ente aggregato specificato.
      config_accessor :ipa do
        nil
      end

      # Se non specificato, il valore di default è SSO=0. Impostando il parametro SSO=1, se l'utente ha già effettuato l'autenticazione di livello almeno
      # pari o superiore a quello richiesto dal servizio di destinazione, potrà accedere senza dover ripetere il login.
      config_accessor :sso do
        nil
      end

      # Permette di aggiungere altre autorizzazioni
      config_accessor :authorization_handlers do
        []
      end

    #  Permette di customizzare il workflow di autorizzazione.
      config_accessor :workflow_configurator do
        lambda do |workflow|
          # Di default, la scadenza è impostata a 0 minuti e quindi non scadrà
          workflow.expires_in = 0.minutes
          workflow.renewable = false
        end
      end

      # Permette di customizzare parte del flusso di autenticazione (come
      # le validazioni) prima che l'utente venga autenticato.
      config_accessor :authenticator_class do
        Decidim::CohesionId::Authentication::Authenticator
      end


      # Permette di customizzare parte del i metadata collezionati dagli
      # attributi SAML.
      config_accessor :metadata_collector_class do
        Decidim::CohesionId::Verification::MetadataCollector
      end

      # Le chiavi che verranno salvate nell'autorizzazione (record Decidim::Authorization)
      config_accessor :metadata_attributes do
        {}
      end

      def initialize
        yield self
      end

      def name=(name)
        raise(InvalidTenantName, "Il nome del tenant #{name} può contenere solo lettere o underscore.") unless name.match?(/^[a-z_]+$/)
        config.name = name
      end

      def authenticator_for(organization, oauth_hash)
        authenticator_class.new(self, organization, oauth_hash)
      end

      def metadata_collector_for(saml_attributes)
        metadata_collector_class.new(self, saml_attributes)
      end

      def run_authorization_handlers(handler_params)
        authorization_handlers.each do |handler_name|
          handler = Decidim::AuthorizationHandler.handler_for(handler_name, handler_params)
          if handler && handler.valid?
            authorization = Decidim::Authorization.find_or_initialize_by(
              user: handler.user,
              name: handler.handler_name
            )
            authorization.attributes = {
              unique_id: handler.unique_id,
              metadata: handler.metadata
            }
            authorization.save

            authorization.grant! unless authorization.granted?
          end
        end
      end

      def omniauth_settings
        {
          name: name,
          strategy_class: OmniAuth::Strategies::CohesionId,
          settings: {
            sso_check_url: config.sso_check_url,
            entity_id: config.entity_id,
            sso_web_check_session: config.sso_web_check_session,
            id_sito: config.id_sito,
            params: {
              auth_restriction: config.auth_restriction,
              url_after_login: config.url_after_login,
              u_type: config.u_type,
              purpose: config.purpose,
              aggregato: config.aggregato,
              eidas: config.eidas,
              spid_mode: config.spid_mode,
              cie_mode: config.cie_mode,
              ipa: config.ipa,
              sso: config.sso
            },
          }
        }
      end

      def setup!
        setup_routes!

        # Configure the SAML OmniAuth strategy for Devise
        ::Devise.setup do |config|
          config.omniauth(name.to_sym, omniauth_settings)
        end

        # Customized version of Devise's OmniAuth failure app in order to handle
        # the failures properly. Without this, the failure requests would end
        # up in an ActionController::InvalidAuthenticityToken exception.
        devise_failure_app = OmniAuth.config.on_failure
        # OmniAuth.config.before_callback_phase do |env|
        #   env['omniauth.origin'] = '/users/show'
        # end
        OmniAuth.config.on_failure = proc do |env|
          if env["PATH_INFO"] && env["PATH_INFO"].match?(%r{^/users/auth/#{config.name}($|/.+)})
            env["devise.mapping"] = ::Devise.mappings[:user]
            Decidim::CohesionId::OmniauthCallbacksController.action(
              :failure
            ).call(env)
          else
            # Call the default for others.
            devise_failure_app.call(env)
          end
        end
      end

      def setup_routes!
        config = self.config
        Decidim::CohesionId::Engine.routes do
          devise_scope :user do
            # Mappatura delle route
            match(
              "/users/auth/#{config.name}",
              to: "omniauth_callbacks#passthru",
              as: "user_#{config.name}_omniauth_authorize",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/callback",
              to: "omniauth_callbacks#cohesion_id",
              as: "user_#{config.name}_omniauth_callback",
              via: [:get, :post]
            )

            match(
              "/users/auth/#{config.name}/create",
              to: "omniauth_callbacks#create",
              as: "user_#{config.name}_omniauth_create",
              via: [:post, :put, :patch]
            )

          end
        end
      end

    end
  end
end
