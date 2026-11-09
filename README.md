# Decidim CohesionId
Autenticazione CohesionId per Decidim v0.30.x. Questa gemma dipende da: [decidim](https://github.com/decidim/decidim/tree/v0.30.9) e [omniauth](https://github.com/omniauth/omniauth).

## Installazione
Aggiungi al tuo Gemfile

```ruby
gem 'decidim-cohesion_id'
```

ed esegui dal terminale
```bash
$ bundle install
$ rails generate decidim:cohesion_id:install TENANT_NAME
$ bundle exec rake assets:precompile
# Ripetere l'installer per ogni tenant di cui si ha bisogno.
```
Sostituire TENANT_NAME con una stringa univoca che identifica il tenant.
Il TENANT_NAME deve essere univoco anche tra CohesionId.

Verranno generati:
1. `config/initializers/decidim-cohesion_id-#{tenant_name}.rb` per configurare CohesionId ad ogni installazione.
   2`verrà automaticamente aggiunto in `config/secrets.yml` nel blocco default la configurazione `omniauth` necessaria. Aggiungere la configurazione ai vari environment a seconda delle esigenze.
3`config/locales/cohesion_id-#{tenant_name}.en.yml` con le etichette necessarie. Duplicare per ogni locale necessaria.

Per modificare o eliminare un tenant è sufficiente modificare o cancellare proprio il file generato in initializers e fare un restart del server.
Qualora si voglia eliminare la gemma è sufficiente eliminare o ripristinare i file generati degli step precedenti.

## Migrazione da versioni precedenti
Da questa versione, per il provider CohesionID, il campo `decidim_identities.uid` non contiene più il Codice Fiscale in chiaro: viene salvato un identificatore pseudonimizzato (`HMAC-SHA256` con prefisso `v1:`), deterministico per tenant/provider/utente.

Se si aggiorna da una versione precedente con dati già in produzione, è necessario pianificare una migrazione dei record esistenti (`provider = cohesion_id`) per evitare disallineamenti tra login futuri e identity già salvate.

È disponibile il task:

```bash
bundle exec rake decidim:cohesion_id:migrate_identity_uids
```

Per simulare senza scrivere su DB:

```bash
DRY_RUN=true bundle exec rake decidim:cohesion_id:migrate_identity_uids
```

Il task converte ogni `uid` legacy (non già prefissato `v1:`) nel nuovo formato pseudonimizzato, limitandosi ai provider CohesionID configurati (più `cohesion_id`).

## Configurazione
Associare nel pannello di amministratore di sistema (/system) il `tenant_name` ad ogni organizzazione CohesionID.
Completare le configurazioni nell'`initializer` di ogni tenant.

```ruby
# config/initializers/decidim-cohesion_id-#{tenant_name}.rb
Decidim::CohesionId.configure do |config|
  #config ...
end
```
tramite il quale potete accedere alle seguenti configurazioni:

Documentazione https://cohesion.regione.marche.it/CohesionDocs/Pubbliche-Amministrazioni-e-Imprese/

| Nome                          | Valore di default                                                                                                                                                                                                  | Descrizione                                                                                                                                                              | Obbligatorio |
|:------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------|
| config.name                   | `'#{tenant_name}'`                                                                                                                                                                                                 | Identificativo univoco di ogni tenant. Compilato automaticamente dall'installer                                                                                          | ✓            |
| config.sp_entity_id           | `Rails.application.secrets.omniauth[:cohesion_id][:entity_id]`                                                                                                                                                     | Dominio del Service Provider                                                                                                                                             | ✓            |
| config.sso_check_url          | `Rails.application.secrets.omniauth[:cohesion_id][:sso_check_url]`. <br/>config/secrets.yml => https://cohesion2.regione.marche.it/SPManager/WAYF.aspx                                                             | Enpoint identity Provider per il login                                                                                                                                   | ✓            |
| config.sso_web_check_session  | `Rails.application.secrets.omniauth[:cohesion_id][:sso_web_check_session]`. <br/>config/secrets.yml => https://cohesion2.regione.marche.it/SPManager/webCheckSessionSSO.aspx                                       | Enpoint identity Provider per recuperare dati utente                                                                                                                     | ✓            |
| config.id_sito                | `Rails.application.secrets.omniauth[:cohesion_id][:id_sito]`. <br/>Bisogna accreditarsi e completare config/secrets.yml                                                                                            | Identificativo univoco rilasciato a seguito dell'accreditamento.                                                                                                         | ✓            |
| config.auth_restriction       | `[1]`                                                                                                                                                                                                              | Livello di autenticazione minimo richiesto. Es: 0 => SPID Livello 1                                                                                                      |              |
| config.url_after_login        | `nil`                                                                                                                                                                                                              | Path relativo al quale l'utente sarà reindirizzato                                                                                                                       |              |
| config.u_type                 | `'c'`                                                                                                                                                                                                              | Tipologia di utente che accede tramite Cohesion. Es: c => solo i cittadini                                                                                               |              |
| config.purpose                | `[]`                                                                                                                                                                                                               | Livello di sicurezza SPID in base alla tipologia. Es. PF => SPID personale per Persona Fisica                                                                            |              |
| config.aggregato              | `nil`                                                                                                                                                                                                              | Se l'ente è federato in modalità aggregata                                                                                                                               |              |
| config.eidas                  | `nil`                                                                                                                                                                                                              | Abilita il login tramite il nodo italiano eIDAS. <br/>Es: 1 => Autenticazione eidas abilitata, nessuna verifica del Codice Fiscale.                                      |              |
| config.spid_mode              | `nil`                                                                                                                                                                                                              | Definisce il protocollo di autenticazione che CohesionID usa con SPID. Es: OIDC => OpenID Connect. Default: nil => SAML                                                  |              |
| config.cie_mode               | `nil`                                                                                                                                                                                                              | Definisce il protocollo di autenticazione che CohesionID usa con CIE. Es: OIDC => OpenID Connect. Default: nil => SAML                                                   |              |
| config.ipa                    | `nil`                                                                                                                                                                                                              | L'IPA è l'Indice delle Pubbliche Amministrazioni, univoco ad ogni ente della Pubblica Amministrazione.                                                                   |              |
| config.sso                    | `nil`                                                                                                                                                                                                              | Impostando il parametro 1 l'utente potrà accedere senza dover ripetere il login, <br/>se l'utente ha già effettuato l'autenticazione di livello almeno pari o superiore. |              |
| config.metadata_attributes    | `[]`                                                                                                                                                                                                               | Attibuti che verranno salvati all'autenticazione con relativo mapping                                                                                                    | ✓            |
| config.authorization_handlers | `[]`                                                                                                                                                                                                               | Permette di aggiungere altre autorizzazioni da eseguire successivamente a CohesionId                                                                                     |              |


```bash
TODO: da verificare questa sezione
Routes for Decidim::CohesionId::Engine:
                       destroy_user_session DELETE|POST    /users/sign_out(.:format)                     decidim/cohesion_id/sessions#destroy
                  slo_callback_user_session GET            /users/slo_callback(.:format)                 decidim/cohesion_id/sessions#slo_callback
     user_#{tenant_name}_omniauth_authorize GET|POST       /users/auth/#{tenant_name}(.:format)          decidim/cohesion_id/omniauth_callbacks#passthru
      user_#{tenant_name}_omniauth_callback GET|POST       /users/auth/#{tenant_name}/callback(.:format) decidim/#{tenant_name}/omniauth_callbacks#cohesion_id
        user_#{tenant_name}_omniauth_create POST|PUT|PATCH /users/auth/#{tenant_name}/create(.:format)   decidim/cohesion_id/omniauth_callbacks#create
           user_#{tenant_name}_omniauth_slo GET|POST       /users/auth/#{tenant_name}/slo(.:format)      decidim/cohesion_id/sessions#slo
         user_#{tenant_name}_omniauth_spslo GET|POST       /users/auth/#{tenant_name}/spslo(.:format)    decidim/cohesion_id/sessions#spslo

Routes for Decidim::CohesionId::Verification::Engine:
                          new_authorization GET           /authorizations/new(.:format)                   decidim/cohesion_id/verification/authorizations#new
                                       root GET           /                                               decidim/cohesion_id/verification/authorizations#new

```

### Views
Il button "Entra con CohesionID" automaticamente viene visualizzato nella pagina di login se l'autenticazione viene abilitata nel pannello di amministratore di sistema (/system).
Per renderizzare il button predefinito:

```ruby
<%= render partial: 'cohesion_id/cohesion_id %> # per personalizzazioni
```
Altrimenti è possibile customizzare la view creando il file app/views/decidim/cohesion_id/_cohesion_id.html.erb.


## Contributori
Gem sviluppata da [Kapusons](https://www.kapusons.it) per [Pares](https://pares.it).

## Segnalazioni sulla sicurezza
La gem utilizza tutte le raccomandazioni e le prescrizioni in materia di sicurezza previste da Decidim e dall’Agenzia per l’Italia Digitale per SPID. E' indispensabile contestualizzare e dettagliare con la massima precisione le segnalazioni. Le segnalazioni anonime o non sufficientemente dettagliate non potranno essere verificate.


## Licenza
Vedi [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt).