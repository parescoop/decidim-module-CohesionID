module Decidim
  module CohesionId
    class Request

      def initialize(settings)
        @settings = settings
        @params = settings.params
      end

      def create(callback_url)
        builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
          xml.dsAuth('xmlns' => 'http://tempuri.org/Auth.xsd', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
            xml.auth {
              xml.user # TODO: non ho capito a cosa serve
              xml.id_sito @settings.id_sito
              xml.esito_auth_sa
              xml.id_session_sa
              xml.id_session_aspnet_sa
              xml.url_validate callback_url
              xml.url_richiesta callback_url
              xml.esito_auth_sso
              xml.id_sessione_sso
              xml.id_sessione_aspnet_sso
              xml.stilesheet additional_data
            }
          }
        end
        puts builder.to_xml if Rails.env.development?
        p = CGI.escape(Base64.strict_encode64(builder.to_xml))
        @settings.sso_check_url + "?auth=#{p}"
      end

      private

      def additional_data
        #AuthRestriction=3,2,1,0;
        #https://cohesion2.regione.marche.it/testcohesion/Index.aspx;
        #UType=d;
        #purpose=PG|PF|LP;
        #aggregato=1;
        #eidas=3;
        #SpidMode=OIDC;
        #CieMode=OIDC;
        #IPA=c_000;
        #SSO=1
        [
          "AuthRestriction=#{@params.auth_restriction.join(',')}",
          "#{@settings.entity_id}#{@params.url_after_login}",
          @params.u_type ? "UType=#{@params.u_type}" : nil,
          @params.purpose.present? ? "purpose=#{@params.purpose.join('|')}" : nil,
          @params.aggregato ? "aggregato=#{@params.aggregato}" : nil,
          @params.eidas ? "eidas=#{@params.eidas}" : nil,
          @params.spid_mode ? "SpidMode=#{@params.spid_mode}" : nil,
          @params.cie_mode ? "CieMode=#{@params.cie_mode}" : nil,
          @params.ipa ? "IPA=#{@params.ipa}" : nil,
          @params.sso ? "SSO=#{@params.sso}" : nil,
        ].compact.join(";")
      end

    end
  end
end
