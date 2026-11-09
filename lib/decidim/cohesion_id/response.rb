require 'decidim/cohesion_id/validation_error'
require 'decidim/cohesion_id/client'
require 'nokogiri'
require 'rexml/document'
require 'rexml/xpath'
require 'uri'

module Decidim
  module CohesionId
    class Response

      attr_accessor :errors

      def initialize(settings, raw_response)
        @settings = settings
        @params = settings.params
        doc = Nokogiri::XML(decode_raw_saml(raw_response, settings))
        doc.remove_namespaces!
        @response = doc.root
        @errors = []
      end

      def valid?(expected_url: nil)
        @errors << "Errore durante l'autenticazione: URL richiesta non valorizzato." if url_richiesta.blank?
        @errors << "Errore durante l'autenticazione: Esito auth non conforme." if esito_auth_sso.blank? || esito_auth_sso != 'OK'
        if expected_url.present? && !valid_request_url?(expected_url)
          @errors << "Errore durante l'autenticazione: URL richiesta non conforme."
        end
        @errors.blank?
      end

      def get_data
        Client.call(@settings, "GetCredential", id_sessione_sso, id_sessione_aspnet_sso)
      end

      private

      def valid_request_url?(expected_url)
        expected = URI.parse(expected_url)
        actual = URI.parse(url_richiesta)

        expected.scheme == actual.scheme &&
          expected.host == actual.host &&
          expected.path == actual.path
      rescue URI::InvalidURIError
        false
      end

      def decode_raw_saml(p, settings = nil)
        Base64.decode64(p)
      rescue Exception => ex
        raise Decidim::CohesionId::ValidationError.new(ex)
      end

      def id
        @id ||= @response.at_xpath('/dsAuth/auth/user').try(:content)
      end

      def id_sessione_sso
        @id_sessione_sso ||= @response.at_xpath('/dsAuth/auth/id_sessione_sso').try(:content)
      end

      def id_sessione_aspnet_sso
        @id_sessione_aspnet_sso ||= @response.at_xpath('/dsAuth/auth/id_sessione_aspnet_sso').try(:content)
      end

      def esito_auth_sso
        @esito_auth_sso ||= @response.at_xpath('/dsAuth/auth/esito_auth_sso').try(:content)
      end

      def url_richiesta
        @url_richiesta ||= @response.at_xpath('/dsAuth/auth/url_richiesta').try(:content)
      end

    end
  end
end
