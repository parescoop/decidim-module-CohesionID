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
              # xml.user # TODO: non ho capito a cosa serve
              xml.id_sito @settings.id_sito
              # xml.esito_auth_sa
              # xml.id_session_sa
              # xml.id_session_aspnet_sa
              xml.url_validate callback_url
              xml.url_richiesta callback_url
              # xml.esito_auth_sso
              # xml.id_sessione_sso
              # xml.id_sessione_aspnet_sso
              xml.stilesheet additional_data
            }
          }
        end
        puts builder.to_xml if Rails.env.development?
#         a = '
# <?xml version="1.0" ?>
# <dsAuth xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://tempuri.org/Auth.xsd">
#     <auth>
#         <user>RSSMRA85D18F051Y</user>
#         <id_sa/>
#         <id_sito>example</id_sito>
#         <esito_auth_sa/>
#         <id_sessione_sa/>
#         <id_sessione_aspnet_sa/>
#         <url_validate>https://example.cohesion.it/Login</url_validate>
#         <url_richiesta>https://example.cohesion.it</url_richiesta>
#         <esito_auth_sso>OK</esito_auth_sso>
#         <id_sessione_sso>A5D64899EBCEE1FA6B3E8FB3D3D358D7E5843EA25EDFD62277CACE8A5EF23B1C5E6FAB916F333B0AFB0FAE6C4CDF7B8E8DEE461E8661DB04F5FFB01BC0EF9FCB90EEA2ACA7988119EFE17D5C3BB58BC890D75D724D434D7D60C2F451F6A51D1DFFA900EF0AAA631A51458860C6CEC7B1EBC525561624208066DF276314F41F6EC258CA3F</id_sessione_sso>
#         <id_sessione_aspnet_sso>ufrq00x4f0cq2yog2ozv4lxx;https://idp.namirialtsp.com/idp;https://example.cohesion.it/LogOff;AAdzZWNyZXQxGLSQhZFb4TSPKKPNCGfO5MaCcJ99DiuEnIzpO4YvtOrgf+6qvwyEVOguFDCVbyPcZ2hhjbBtPtuCWUGs+FYX9zREfvZ1heshK7yzE24MU7JsIBK17atMdbL31QbDPNKbH2wiswXhL2CJGjY=;AAdzZWNyZXQxGLSQhZFb4TSPKKPNCGfO5MaCcJ99DiuEnIzpO4YvtOrgf+6qvwyEVOguFDCVbyPcZ2hhjbBtPtuCWUGs+FYX9zREfvZ1heshK7yzE24MU7JsIBK17atMdbL31QbDPNKbH2wiswXhL2CJGjY=;</id_sessione_aspnet_sso>
#         <stilesheet>AuthRestriction=1,2,3;https://example.cohesion.it/LogOff</stilesheet>
#         <ip xmlns="">cohesion2.regione.marche.it</ip>
#         <AuthRestriction xmlns="">1,2,3</AuthRestriction>
#         <UType xmlns="">CD</UType>
#         <purpose xmlns=""/>
#         <url_logout xmlns="">https://example.cohesion.it/LogOff</url_logout>
#         <cittad xmlns="">1</cittad>
#     </auth>
# </dsAuth>
# '
#         puts CGI.escape(Base64.strict_encode64(a))
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
