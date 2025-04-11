module Decidim
  module CohesionId
    class UpdateEmailCohesionIdJob < ApplicationJob
      queue_as :default

      def perform(user)
        return if user&.email.blank?

        CohesionIdMailer.send_update_email_notification(user).deliver_now
      end
    end
  end
end
