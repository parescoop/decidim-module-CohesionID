module Decidim
  module CohesionId
    class Client

      def initialize(settings, operation, id_sessione_sso = '', id_sessione_aspnet_sso = '')
        @settings = settings
        @operation = operation
        @id_sessione_sso = id_sessione_sso
        @id_sessione_aspnet_sso = id_sessione_aspnet_sso
      end

      def self.call(settings, operation, id_sessione_sso = '', id_sessione_aspnet_sso = '')
        new(settings, operation, id_sessione_sso, id_sessione_aspnet_sso).call
      end

      def call
        params = {
           "Operation": @operation,
           "IdSessioneSSO": @id_sessione_sso,
           "IdSessioneASPNET": @id_sessione_aspnet_sso
        }
        response = Faraday.post @settings.sso_web_check_session, params
        if response.body && response.body.match(/<AUTH>NO<\/AUTH>/)
          raise Decidim::CohesionId::ValidationError.new("Si è verificato un errore durante il recupero dei dati")
        else
          parse_token_to_hash(response.body)
        end
      rescue Exception => ex
        raise Decidim::CohesionId::ValidationError.new(ex)
      end

      def parse_token_to_hash(token)
        return if token.blank?
        doc = Nokogiri::XML(token)
        doc.remove_namespaces!
        # TODO: ogni plugin non verifica la signature
        base = doc.at_xpath('/Signature/Object/profile/base')

        hash = {}

        base.elements.each do |element|
          hash[element.name] = element.text.strip
        end

        hash.merge(id_sessione_aspnet_sso: @id_sessione_aspnet_sso, id_sessione_sso: @id_sessione_sso).symbolize_keys
      end
    end
  end
end
