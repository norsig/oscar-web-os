describe 'Location' do
  let!(:admin){ create(:user, roles: 'admin') }
  let!(:location){ create(:location) }

  before do
    login_as(admin)
  end

  feature 'List' do
    before do
      FactoryGirl.create_list(:location, 20)
      visit locations_path
    end

    scenario 'name' do
      expect(page).to have_content(location.name)
    end

    scenario 'edit link' do
      expect(page).to have_link(nil, edit_location_path(location))
    end

    scenario 'delete link' do
      expect(page).to have_css("a[href='#{location_path(location)}'][data-method='delete']")
    end

    scenario 'new link' do
      expect(page).to have_link(I18n.t('locations.index.add_new_location'), new_location_path)
    end

    scenario 'pagination' do
      expect(page).to have_css('.pagination')
    end
  end

  feature 'Create' do
    before do
      visit new_location_path
    end

    scenario 'valid' do
      fill_in I18n.t('locations.form.name'), with: FFaker::Company.name
      click_button I18n.t('locations.form.save')
      expect(page).to have_content(I18n.t('locations.create.successfully_created'))
    end

    scenario 'invalid' do
      click_button I18n.t('locations.form.save')
      expect(page).to have_content("can't be blank")
    end
  end

  feature 'Edit' do
    let!(:name) { FFaker::Company.name }
    let!(:other_location) { create(:location, name: 'Home') }
    before do
      visit edit_location_path(location)
    end
    scenario 'valid' do
      fill_in I18n.t('locations.form.name'), with: name
      click_button I18n.t('locations.form.save')
      expect(page).to have_content(I18n.t('locations.update.successfully_updated'))
      expect(page).to have_content(name)
    end
    scenario 'invalid' do
      fill_in I18n.t('locations.form.name'), with: 'Home'
      click_button I18n.t('locations.form.save')
      expect(page).to have_content(I18n.t('activerecord.errors.models.location.attributes.name.taken'))
    end
  end

  feature 'Delete' do
    before do
      visit locations_path
    end
    scenario 'success' do
      find("a[href='#{location_path(location)}'][data-method='delete']").click
      expect(page).to have_content(I18n.t('locations.destroy.successfully_deleted'))
    end
  end
end
