Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "remove-instructions-sessions-cohesion_id",
                     remove: "div.login__info")

Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "remove-instructions-sessions-cohesion_id-2",
                     remove: "span.login__info-separator")


Deface::Override.new(virtual_path: "decidim/devise/sessions/new",
                     name: "append-instructions-sessions-cohesion_id",
                     insert_after: "erb:contains('current_organization.sign_in_enabled?')") do
  '
    <div class="login__info text-center mt-12">
      <% if current_organization.sign_up_enabled? && current_organization.enabled_omniauth_providers.dig(:cohesion_id).present? %>
        <p>
          <%= t("decidim.cohesion_id.omniauth_callbacks.new.cohesion_id_sessions_help", link: link_to(t("decidim.devise.registrations.new.sign_up").try(:downcase), new_user_registration_path)).html_safe %>
        </p>
      <% elsif current_organization.sign_up_enabled? %>
        <p>
          <%= t("decidim.devise.sessions.new.are_you_new?") %>
          <%= link_to t("decidim.devise.sessions.new.register"), new_user_registration_path %>
        </p>
      <% elsif current_organization.sign_in_enabled? %>
        <p>
          <%= t("decidim.devise.sessions.new.sign_up_disabled") %>
        </p>
      <% else %>
        <p>
          <%= t("decidim.devise.sessions.new.sign_in_disabled") %>
        </p>
      <% end %>
    </div>
'
end