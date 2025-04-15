Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "remove-instructions-cohesion_id",
                     remove: "div.login__info")

Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "remove-instructions-cohesion_id-2",
                     remove: "div.login__info-required")

Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "remove-instructions-cohesion_id-3",
                     remove: "span.login__info-separator")

Deface::Override.new(virtual_path: "decidim/devise/registrations/new",
                     name: "append-instructions-cohesion_id",
                     insert_before: "erb:contains('decidim_form_for')") do
  '
    <%- if current_organization.enabled_omniauth_providers.dig(:cohesion_id).present? %>
      <div class="login__info text-center mt-12">
        <p>
          <%= t("decidim.cohesion_id.omniauth_callbacks.new.cohesion_id_help", link: link_to(t("decidim.devise.registrations.new.log_in").try(:downcase), new_user_session_path)).html_safe %>
        </p>
      </div>
    <% end %>
'
end