require 'decidim/cohesion_id/secret_modifier'

module Decidim
  module CohesionId
    module Generators
      class InstallGenerator < Rails::Generators::Base
        source_root File.expand_path('templates', __dir__)

        desc "Crea un Decidim CohesionID Tenant"
        argument :tenant_name, type: :string

        def copy_initializer
          if Decidim::CohesionId.tenants.map(&:name).include?(tenant_name)
            say_status(:conflict, "Esiste già un tenant con questo nome", :red)
            exit
          end
          say_status(:conflict, "Il nome del tenant CohesionId può contenere solo lettere o underscore.", :red) && exit unless tenant_name.match?(/^[a-z_]+$/)
          template "decidim-cohesion_id.rb", "config/initializers/decidim-cohesion_id-#{tenant_name}.rb"
        end

        def enable_authentication
          secrets_path = Rails.application.root.join("config", "secrets.yml")
          secrets = YAML.safe_load(ERB.new(File.read(secrets_path)).result, permitted_classes: [], permitted_symbols: [], aliases: true)
          if secrets.dig("default", "omniauth", "cohesion_id")
            say_status :identical, "config/secrets.yml", :blue
          else
            mod = SecretsModifier.new(secrets_path, tenant_name)
            final = mod.modify

            target_path = Rails.application.root.join("config", "secrets.yml")
            File.open(target_path, "w") { |f| f.puts final }

            say_status :insert, "config/secrets.yml", :green
          end
          say_status :skip, "Ricorda di modificare config/secrets.yml omniauth se le configurazioni di :default non sono incluse", :yellow
        end

        def locales
          template "cohesion_id.en.yml", "config/locales/cohesion_id-#{tenant_name}.en.yml"
          template "cohesion_id.it.yml", "config/locales/cohesion_id-#{tenant_name}.it.yml"
          say_status :skip, "Completa le traduzione con le lingue disponibili config/locales/cohesion_id-#{tenant_name}.en.yml", :yellow
        end

        def organizations
          say_status :skip, "Ricorda di associare le organizzazioni con il relativo tenant in amministrazione", :yellow
        end


      end

    end
  end
end