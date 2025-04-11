module Decidim
  module CohesionId
    class CohesionIdJob < ApplicationJob
      queue_as :default

      def perform(user)
        return if user&.email.blank?

        CohesionIdMailer.send_notification(user).deliver_now
      end
    end
  end
end
