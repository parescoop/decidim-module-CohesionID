# frozen_string_literal: true

Decidim::CohesionId.configure do |config|
  # Definisce il nome del tenant. Solo lettere minuscole e underscores sono permessi.
  # Default: cohesionID. Quando hai multipli tenant devi definire un nome univoco rispetto ai vari tenant.
  config.name = "<%= tenant_name %>"

  # Dominio tenant
  config.entity_id = "<%= entity_id %>"

  ## Provider WAYF endpoint. Default: CohesionId in secrets.yml
  ## Production: 'https://cohesion2.regione.marche.it/SPManager/WAYF.aspx'
  ## Staging: 'https://cohesion2.regione.marche.it/SPManager/WAYF.aspx'
  config.sso_check_url = Rails.application.secrets.omniauth[:cohesion_id][:sso_check_url]

  # Definisce SSOwebCheckSession:
  config.sso_web_check_session = Rails.application.secrets.omniauth[:cohesion_id][:sso_web_check_session]

  # TODO: DA verificare se devono essere configurabili
  # config.sso_additional_data = "AuthRestriction=0,1,2,3;<%= entity_id %>/Account/LogOff"
  # config.site_index_url = "<%= entity_id %>/Account/Login"
  # config.site_url_logout = "../Logout.aspx?ReturnUrl=https%3A%2F%2Fcohesion2.regione.marche.it%2FSPManager%2FLogout.aspx"
  config.id_sito = Rails.application.secrets.omniauth[:cohesion_id][:id_sito]

  # Docs: https://cohesion.regione.marche.it/CohesionDocs/Parametri-della-Richiesta-di-Autenticazione/
  # Default: 1 = Accesso con password e PIN o token OTP - SPID Livello 2
  # config.auth_restriction = [1]

  # L'URL al quale l'utente sarà reindirizzato dopo aver effettuato l'autenticazione.
  # config.url_after_login = nil # Default: nil => Homepage altrimenti specificare url relativo

  # Default: UType=c = Accesso per soli cittadini, l'autenticazione tramite credenziali Cohesion è disabilitata
  # config.u_type = 'c'

  # Ad esempio, impostando il parametro come purpose='PG' Cohesion consentirà l'accesso solamente alle persone dotate di SPID Giuridico.
  # Deve essere un array
  # config.purpose = []

  # Se l'ente è federato in modalità aggregata, sarà necessario inserire il parametro aggregato=1
  # config.aggregato = nil

  # Abilita il login tramite il nodo italiano eIDAS specificando se, a valle dell'autenticazione, è necessaria la verifica del Codice Fiscale
  # config.eidas = nil

  # Se non specificato, verrà utilizzato il protocollo di default SAML. Impostando il parametro come SpidMode=OIDC verrà utilizzato il nuovo protocollo OpenID Connect
  # config.spid_mode = nil

  # Se non specificato, verrà utilizzato il protocollo di default SAML. Impostando il parametro come SpidMode=OIDC verrà utilizzato il nuovo protocollo OpenID Connect
  # config.cie_mode = nil

  # Specificando questo parametro, CohesionId effettuerà la richiesta di autenticazione verso le piattaforme nazionali ed europee per conto dell'ente aggregato specificato.
  # config.ipa = nil

  # Se non specificato, il valore di default è SSO=0. Impostando il parametro SSO=1, se l'utente ha già effettuato l'autenticazione di livello almeno
  # pari o superiore a quello richiesto dal servizio di destinazione, potrà accedere senza dover ripetere il login.
  # config.sso = nil

  # Le chiavi che verranno salvate sul DB nell'autorizzazione
  config.metadata_attributes = {
    name: "nome",
    surname: "cognome",
    fiscal_code: "CodiceFiscale",
    gender: "sesso",
    birthday: "dataNascita",
    birthplace: "luogoNascita",
    company_name: "companyName",
    registered_office: "registeredOffice",
    iva_code: "ivaCode",
    id_card: "idCard",
    mobile_phone: "cellulare",
    email: "emailAddressPersonale",
    address: "indirizzoResidenza",
    digital_address: "emailAddress",
    spid_code: "spidCode"
  }

  # Permette di aggiungere altre autorizzazioni. Es: ["census_authorization_handler"]
  # config.authorization_handlers =  []


end