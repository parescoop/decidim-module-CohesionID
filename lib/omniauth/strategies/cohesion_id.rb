
# require 'openssl'
# require 'rack/utils'
# require 'uri'

require "decidim/cohesion_id/request"
require "decidim/cohesion_id/response"
require "decidim/cohesion_id/client"
require "decidim/cohesion_id/validation_error"

module OmniAuth
  module Strategies
    class CohesionId

      include OmniAuth::Strategy

      # def self.inherited(subclass)
      #   OmniAuth::Strategy.included(subclass)
      # end

      option :uid_attribute, :codice_fiscale

      # DEFAULT_SCOPE = 'email'

      # def client
      #   ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options))
      # end

      def request_phase
        request = Decidim::CohesionId::Request.new(options.settings)
        redirect request.create(callback_url)
      end

      uid do
        if options.uid_attribute
          ret =  @attributes.dig(options.uid_attribute)
          if ret.nil?
            raise OmniAuth::Strategies::SAML::ValidationError.new("SAML response missing '#{options.uid_attribute}' attribute")
          end
          ret
        else
          @name_id
        end
      end

      info do
        @attributes
      end

      # extra { { :raw_info => @attributes, :session_index => @session_index, :response_object =>  @response_object } }

      def callback_phase
        raise Decidim::CohesionId::ValidationError.new("XML response missing") unless request.params["auth"]

        # with_settings do |settings|
          # Call a fingerprint validation method if there's one
          # validate_fingerprint(settings) if options.idp_cert_fingerprint_validator

        response = Decidim::CohesionId::Response.new(options.settings, request.params["auth"])
        if response.valid? && parse_data(response.get_data)
          env['omniauth.auth'] = auth_hash
          call_app!
        else
          raise Decidim::CohesionId::ValidationError.new(response.errors.try(:first))
        end
        # end
      rescue Decidim::CohesionId::ValidationError
        fail!(:invalid_ticket, $!)
      end

      def parse_data(data)
        @name_id = data.dig(:codice_fiscale)
        @id_sessione_sso = data.dig(:id_sessione_sso) # forse rimuoverlo dagli attributi e inserirlo in sessione se serve al logout
        @id_sessione_aspnet_sso = data.dig(:id_sessione_aspnet_sso)  # forse rimuoverlo dagli attributi e inserirlo in sessione se serve al logout
        @attributes = data
        # @response_object = response
      rescue Exception => ex
        raise Decidim::CohesionId::ValidationError.new(ex)
      end

      def other_phase
        if on_path?(slo_path)
          @env['omniauth.strategy'] ||= self
          setup_phase

          other_phase_for_slo
        else
          call_app!
        end
      end

      def other_phase_for_slo
        #TODO: check request and options
        Client.call(settings, "LogoutSito", @id_sessione_sso, @id_sessione_aspnet_sso)
      ensure
        redirect('/') #TODO: URL AFTER LOGOUT
      end

      def slo_path
        @slo_path ||= begin
                     path ||= "#{script_name}#{path_prefix}/#{name}/slo"
                     path
                   end
      end

      # option :client_options, {
      #   site: 'https://graph.facebook.com/v2.10',
      #   authorize_url: "https://www.facebook.com/v2.10/dialog/oauth",
      #   token_url: 'oauth/access_token'
      # }
      #
      # option :access_token_options, {
      #   header_format: 'OAuth %s',
      #   param_name: 'access_token'
      # }
      #
      # option :authorize_options, [:scope, :display, :auth_type]
      #
      # uid { raw_info['id'] }
      #
      # info do
      #   prune!({
      #            'nickname' => raw_info['username'],
      #            'email' => raw_info['email'],
      #            'name' => raw_info['name'],
      #            'first_name' => raw_info['first_name'],
      #            'last_name' => raw_info['last_name'],
      #            'image' => image_url(uid, options),
      #            'description' => raw_info['bio'],
      #            'urls' => {
      #              'Facebook' => raw_info['link'],
      #              'Website' => raw_info['website']
      #            },
      #            'location' => (raw_info['location'] || {})['name'],
      #            'verified' => raw_info['verified']
      #          })
      # end
      #
      # extra do
      #   hash = {}
      #   hash['raw_info'] = raw_info unless skip_info?
      #   prune! hash
      # end
      #
      # def raw_info
      #   @raw_info ||= access_token.get('me', info_options).parsed || {}
      # end
      #
      # def info_options
      #   params = {appsecret_proof: appsecret_proof}
      #   params.merge!({fields: (options[:info_fields] || 'name,email')})
      #   params.merge!({locale: options[:locale]}) if options[:locale]
      #
      #   { params: params }
      # end
      #
      # def callback_phase
      #   with_authorization_code! do
      #     super
      #   end
      # rescue NoAuthorizationCodeError => e
      #   fail!(:no_authorization_code, e)
      # rescue OmniAuth::Facebook::SignedRequest::UnknownSignatureAlgorithmError => e
      #   fail!(:unknown_signature_algorithm, e)
      # end
      #
      # # NOTE If we're using code from the signed request then FB sets the redirect_uri to '' during the authorize
      # #      phase and it must match during the access_token phase:
      # #      https://github.com/facebook/facebook-php-sdk/blob/master/src/base_facebook.php#L477
      # def callback_url
      #   if @authorization_code_from_signed_request_in_cookie
      #     ''
      #   else
      #     # Fixes regression in omniauth-oauth2 v1.4.0 by https://github.com/intridea/omniauth-oauth2/commit/85fdbe117c2a4400d001a6368cc359d88f40abc7
      #     options[:callback_url] || (full_host + script_name + callback_path)
      #   end
      # end
      #
      # def access_token_options
      #   options.access_token_options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }
      # end
      #
      # # You can pass +display+, +scope+, or +auth_type+ params to the auth request, if you need to set them dynamically.
      # # You can also set these options in the OmniAuth config :authorize_params option.
      # #
      # # For example: /auth/facebook?display=popup
      # def authorize_params
      #   super.tap do |params|
      #     %w[display scope auth_type].each do |v|
      #       if request.params[v]
      #         params[v.to_sym] = request.params[v]
      #       end
      #     end
      #
      #     params[:scope] ||= DEFAULT_SCOPE
      #   end
      # end
      #
      # protected
      #
      # def build_access_token
      #   super.tap do |token|
      #     token.options.merge!(access_token_options)
      #   end
      # end
      #
      # private
      #
      # def signed_request_from_cookie
      #   @signed_request_from_cookie ||= raw_signed_request_from_cookie && OmniAuth::Facebook::SignedRequest.parse(raw_signed_request_from_cookie, client.secret)
      # end
      #
      # def raw_signed_request_from_cookie
      #   request.cookies["fbsr_#{client.id}"]
      # end
      #
      # # Picks the authorization code in order, from:
      # #
      # # 1. The request 'code' param (manual callback from standard server-side flow)
      # # 2. A signed request from cookie (passed from the client during the client-side flow)
      # def with_authorization_code!
      #   if request.params.key?('code')
      #     yield
      #   elsif code_from_signed_request = signed_request_from_cookie && signed_request_from_cookie['code']
      #     request.params['code'] = code_from_signed_request
      #     @authorization_code_from_signed_request_in_cookie = true
      #     # NOTE The code from the signed fbsr_XXX cookie is set by the FB JS SDK will confirm that the identity of the
      #     #      user contained in the signed request matches the user loading the app.
      #     original_provider_ignores_state = options.provider_ignores_state
      #     options.provider_ignores_state = true
      #     begin
      #       yield
      #     ensure
      #       request.params.delete('code')
      #       @authorization_code_from_signed_request_in_cookie = false
      #       options.provider_ignores_state = original_provider_ignores_state
      #     end
      #   else
      #     raise NoAuthorizationCodeError, 'must pass either a `code` (via URL or by an `fbsr_XXX` signed request cookie)'
      #   end
      # end
      #
      # def prune!(hash)
      #   hash.delete_if do |_, value|
      #     prune!(value) if value.is_a?(Hash)
      #     value.nil? || (value.respond_to?(:empty?) && value.empty?)
      #   end
      # end
      #
      # def image_url(uid, options)
      #   uri_class = options[:secure_image_url] ? URI::HTTPS : URI::HTTP
      #   site_uri = URI.parse(client.site)
      #   url = uri_class.build({host: site_uri.host, path: "#{site_uri.path}/#{uid}/picture"})
      #
      #   query = if options[:image_size].is_a?(String) || options[:image_size].is_a?(Symbol)
      #             { type: options[:image_size] }
      #           elsif options[:image_size].is_a?(Hash)
      #             options[:image_size]
      #           end
      #   url.query = Rack::Utils.build_query(query) if query
      #
      #   url.to_s
      # end
      #
      # def appsecret_proof
      #   @appsecret_proof ||= OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, client.secret, access_token.token)
      # end
    end
  end
end
