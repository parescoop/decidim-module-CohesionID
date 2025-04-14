Deface::Override.new(virtual_path: "decidim/devise/omniauth_registrations/new",
                     name: "disable-email-field-cohesion_id",
                     replace: "erb:contains('decidim_form_for(@form, namespace: \"registration\", as: resource_name, url: decidim.omniauth_registrations_path(resource_name)')",
                     closing_selector: "erb[silent]:contains('end')" ) do
  '


<%= decidim_form_for(@form, namespace: "registration", as: resource_name, url: omniauth_registrations_path(resource_name)) do |f| %>

    <div class="form__wrapper">
      <%= f.text_field :name, help_text: t("decidim.devise.omniauth_registrations.new.username_help"), autocomplete: "name", placeholder: "John Doe" %>

      <%= f.text_field :nickname, help_text: t("decidim.devise.omniauth_registrations.new.nickname_help", organization: current_organization.name), autocomplete: "nickname", placeholder: "johndoe" %>

      <%= f.email_field :email, readonly: session["decidim-cohesion_id.tenant"].present? && f.object.email.present?, placeholder: t("placeholder_email", scope: "decidim.devise.shared") %>
      <%= f.hidden_field :raw_data %>
      <%= f.hidden_field :invitation_token %>
      <div id="card__newsletter" class="form__wrapper-block">
        <h2 class="h4"><%= t("decidim.devise.registrations.new.newsletter_title") %></h2>
        <%= f.check_box :newsletter, label: t("decidim.devise.registrations.new.newsletter"), checked: @form.newsletter, label_options: { class: "form__wrapper-checkbox-label" } %>
      </div>

      <%= f.hidden_field :uid %>
      <%= f.hidden_field :provider %>
      <%= f.hidden_field :oauth_signature %>
    </div>

    <div class="form__wrapper-block">
      <button type="submit" class="button button__lg button__secondary">
        <span><%= t("decidim.devise.omniauth_registrations.new.complete_profile") %></span>
        <%= icon "arrow-right-line", class: "fill-current" %>
      </button>
    </div>
  <% end %>
'
end