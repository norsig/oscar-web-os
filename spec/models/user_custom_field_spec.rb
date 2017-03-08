describe UserCustomField, 'associations' do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:custom_field) }
  it { is_expected.to validate_presence_of(:user_id) }
  it { is_expected.to validate_presence_of(:custom_field_id) }
end

describe UserCustomField, 'scopes' do
  let!(:user){ create(:user) }
  let!(:cf1){ create(:custom_field, entity_type: 'User', form_title: 'Health Record') }
  let!(:cf2){ create(:custom_field, entity_type: 'User', form_title: 'Care Record') }
  let!(:ucf1){ create(:user_custom_field, user: user, custom_field: cf1) }
  let!(:ucf2){ create(:user_custom_field, user: user, custom_field: cf2) }
  let!(:ucf3){ create(:user_custom_field, user: user, custom_field: cf2) }

  it 'by_custom_field' do
    expect(user.user_custom_fields.by_custom_field(cf2)).to include(ucf2, ucf3)
    expect(user.user_custom_fields.by_custom_field(cf2)).not_to include(ucf1)
  end
end
