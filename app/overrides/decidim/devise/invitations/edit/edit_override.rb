Deface::Override.new(virtual_path: "decidim/devise/invitations/edit",
                     name: "add-cohesion_id-login",
                     surround_contents: "erb:contains('render layout: \"layouts/decidim/shared/layout_center\"')",
                     closing_selector: "erb[silent]:contains('end')" ) do
  '
  <%- if current_organization.enabled_omniauth_providers.keys.include?(:cohesion_id) %>
    <div class="text-center py-12">
      <h1 class="title-decorator inline-block text-left mb-12">
        <%= t "decidim.cohesion_id.devise.invitations.edit.header" %>
      </h1>

      <p class="text-lg text-gray-2">
        <%= t("decidim.cohesion_id.devise.invitations.edit.subtitle").html_safe %>
      </p>
    </div>

    <%- if current_organization.enabled_omniauth_providers.keys.include?(:cohesion_id) %>
      <div class="login__omniauth">
        <% size = current_organization.enabled_omniauth_providers.dig(:cohesion_id, :button_size).presence || "xl" %>
        <% link_classes = "login__omniauth-button button--cohesion_id button--#{size}" %>
        <%= link_to decidim_cohesion_id.send("user_#{current_organization.enabled_omniauth_providers.dig(:cohesion_id, :tenant_name)}_omniauth_authorize_path", locale: I18n.locale), class: link_classes, method: :post, title: t("devise.shared.links.log_in_with_provider", provider: "cohesion_id".titleize) do %>
          <span>
            <%= t("devise.shared.links.sign_in_with_provider_cohesion_id") %>
          </span>
        <% end %>
      </div>
    <% end %>
  <% else %>
    <%= render_original %>
  <% end %>
'
end