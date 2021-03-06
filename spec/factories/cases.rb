FactoryGirl.define do
  factory :case do
    start_date FFaker::Time.date
    carer_names FFaker::Name.name
    carer_address FFaker::Address.street_address
    exited false
    association :family, factory: :family
    association :client, factory: :client
    association :province, factory: :province
    association :partner, factory: :partner

    trait :inactive do
      exited true
      exit_date { Time.now }
      exit_note FFaker::Lorem.paragraph
    end

    trait :emergency do
      case_type 'EC'
    end

    trait :foster do
      case_type 'FC'
    end

    trait :kinship do
      case_type 'KC'
    end
  end
end
