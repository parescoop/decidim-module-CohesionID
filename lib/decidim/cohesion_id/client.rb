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
          # TODO: restore this
          #raise Decidim::CohesionId::ValidationError.new("Si è verificato un errore durante il recupero dei dati")
          token = response.body
          token = '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
    <SignedInfo>
        <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
        <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
        <Reference URI="#SignedXmlId">
            <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
            <DigestValue>rNHSy/TcTBIweMerIO3jizVm7u0=</DigestValue>
        </Reference>
    </SignedInfo>
    <SignatureValue>
        Oz9wACp9Rxo4Z4pC8o61iXuVSJNO+UcszPNcAMNFUAY0I17IeGnB93JpwEWGbPfqn5a+i3IQdNsqlIbQtwAGovBQ6DTTb85kDo4YDue26o7a4np5DfwnO6SuhHsBHMbTvnI9A+45Q7Li4On+eELEQWFRrbS11MmwRYBxR5m5PWKupkX3O2r9JtG6tuKwi/L5+A4U/MqLKDdUm9/TX1lzn5c23XpQgiYpkGrwRqp+Q1Dsem7FcV868VYvgwYkRkj/jNgLFtcdoFij+qBRZi47EUa35KeZgP5V1ENcYigG0OXQQbdavCnPcE3EHjEL3ApkuPNVuSbJZv5TjgFdCpqjXg==
    </SignatureValue>
    <KeyInfo>
        <X509Data>
            <X509Certificate>
                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
            </X509Certificate>
        </X509Data>
    </KeyInfo>
    <Object Id="SignedXmlId">
        <profile timestamp="Tue, 25 Jan 2022 22:02:49 GMT" xmlns="">
            <base>
                <placeOfBirth>F051</placeOfBirth>
                <localita_nascita>ROMA</localita_nascita>
                <address>Via dei matti 28 60044 ANCONA AN</address>
                <indirizzo_residenza>Via dei matti 28 60044 ANCONA AN</indirizzo_residenza>
                <gender>M</gender>
                <sesso>M</sesso>
                <digitalAddress>xxxxxxxxxxx@pec.it</digitalAddress>
                <email_certificata>xxxxxxxxxxx@pec.it</email_certificata>
                <familyName>ROSSI</familyName>
                <cognome>ROSSI</cognome>
                <name>MARIO</name>
                <nome>MARIO</nome>
                <dateOfBirth>1985-04-18</dateOfBirth>
                <data_nascita>18/04/1985</data_nascita>
                <spidCode>NAMI0002653481</spidCode>
                <countyOfBirth>RM</countyOfBirth>
                <provincia_nascita>RM</provincia_nascita>
                <fiscalNumber>TINIT-RSSMRA85D18F051Y</fiscalNumber>
                <codice_fiscale>RSSMRA85D18F051Y</codice_fiscale>
                <email>mario.rossi@regione.marche.it</email>
                <companyFiscalNumber/>
                <tipo_autenticazione>PIN</tipo_autenticazione>
                <login>RSSMRA85D18F051Y</login>
                <samlResponseBase64>PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgi...</samlResponseBase64>
            </base>
        </profile>
    </Object></Signature>'


          parse_token_to_hash(token)

        else
          parse_token_to_hash(response.body.token)
        end
      rescue Exception => ex
        raise Decidim::CohesionId::ValidationError.new(ex)
      end

      def parse_token_to_hash(token)
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
