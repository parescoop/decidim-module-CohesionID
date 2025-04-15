# frozen_string_literal: true

module Decidim
  module CohesionId
    module Admin
      module ApplicationHelper

        def cohesion_id_icon
          content_tag :span, class: 'cohesion_id-badge' do
            image_pack_tag 'media/images/cohesionblack.png', alt: "CohesionID Icon"
          end
        end
      end
    end
  end
end
