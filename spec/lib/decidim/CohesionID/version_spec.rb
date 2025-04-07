# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe CohesionID do
    subject { described_class }

    it "has version" do
      expect(subject.version).to eq("0.28.5")
    end
  end
end
