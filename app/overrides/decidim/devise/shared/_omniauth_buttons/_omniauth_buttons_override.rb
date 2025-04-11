Deface::Override.new(virtual_path: "decidim/devise/shared/_omniauth_buttons",
                     name: "add-provider-button-cohesion_id",
                     insert_after: "erb[silent]:contains('current_organization.enabled_omniauth_providers.keys.each do |provider|')") do
  '
    <%- if provider == :cohesion_id %>
      <% size = current_organization.enabled_omniauth_providers.dig(:cohesion_id, :button_size).presence || "m" %>
      <% link_classes = "login__omniauth-button button--#{normalize_provider_name(provider)} button--#{size}" %>
      <%= link_to decidim_cohesion_id.send("user_#{current_organization.enabled_omniauth_providers.dig(:cohesion_id, :tenant_name)}_omniauth_authorize_path"), class: link_classes, method: :post, title: t("devise.shared.links.log_in_with_provider", provider: normalize_provider_name(provider).titleize) do %>
        <span>
          <%= t("devise.shared.links.sign_in_with_provider_cohesion_id") %>
        </span>
      <% end %>
      <% next %>
    <% end %>
'
end