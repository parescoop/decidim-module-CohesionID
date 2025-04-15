Deface::Override.new(virtual_path: "decidim/admin/officializations/index",
                     name: "add-badge-cohesion_id",
                     insert_before: 'div.card tbody tr td erb[loud]:contains("translated_attribute(user.officialized_as)")') do
'
  <%= user.must_log_with_cohesion_id? ? cohesion_id_icon : "" %>
'
end