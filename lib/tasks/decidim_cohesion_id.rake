# frozen_string_literal: true

require "openssl"

namespace :decidim do
  namespace :cohesion_id do
    desc "Migrate legacy Decidim::Identity uid (CF in chiaro) to v1 HMAC format"
    task migrate_identity_uids: :environment do
      secret = Rails.application.secret_key_base.to_s
      if secret.blank?
        raise "Rails.application.secret_key_base non valorizzata: impossibile migrare gli uid CohesionID"
      end

      dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", "false"))
      providers = (Decidim::CohesionId.tenants.map(&:name) + ["cohesion_id"]).uniq
      scope = Decidim::Identity.where(provider: providers).where("uid IS NOT NULL AND uid <> ''")
      total = scope.count
      migrated = 0
      skipped = 0
      failures = 0

      puts "[decidim:cohesion_id:migrate_identity_uids] start (dry_run=#{dry_run}) - providers=#{providers.join(',')} - total identities: #{total}"

      scope.find_each(batch_size: 500) do |identity|
        uid = identity.uid.to_s
        if uid.start_with?("v1:")
          skipped += 1
          next
        end

        provider = identity.provider.to_s
        tenant_name = provider.presence || "cohesion_id"
        payload = "#{tenant_name}:#{provider}:#{uid}"
        hashed_uid = "v1:#{OpenSSL::HMAC.hexdigest("SHA256", secret, payload)}"

        if dry_run
          migrated += 1
          next
        end

        begin
          identity.update_columns(uid: hashed_uid, updated_at: Time.current)
          migrated += 1
        rescue StandardError => e
          failures += 1
          puts "[decidim:cohesion_id:migrate_identity_uids] ERROR identity_id=#{identity.id}: #{e.class} #{e.message}"
        end
      end

      puts "[decidim:cohesion_id:migrate_identity_uids] done - migrated=#{migrated}, skipped=#{skipped}, failures=#{failures}, dry_run=#{dry_run}"
      raise "Migrazione completata con errori (failures=#{failures})" if failures.positive?
    end
  end
end
