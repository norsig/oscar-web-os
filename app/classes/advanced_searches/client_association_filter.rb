module AdvancedSearches
  class ClientAssociationFilter
    def initialize(clients, field, operator, values)
      @clients  = clients
      @field    = field
      @operator = operator
      @value   = values
    end

    def get_sql
      sql_string = 'clients.id IN (?)'
      case @field
      when 'placement_date'
        values = placement_date_field_query
      when 'form_title'
        values = form_title_field_query
      when 'case_type'
        values = case_type_field_query
      when 'user_id'
        values = user_id_field_query
      when 'agency_name'
        values = agency_name_field_query
      when 'family_id'
        values = family_id_field_query
      when 'family'
        values = family_name_field_query
      when 'age'
        values = age_field_query
      when 'referred_to_ec'
        values = program_placement_date_field_query('EC')
      when 'referred_to_fc'
        values = program_placement_date_field_query('FC')
      when 'referred_to_kc'
        values = program_placement_date_field_query('KC')
      when 'exit_ec_date'
        values = program_exit_date_field_query('EC')
      when 'exit_fc_date'
        values = program_exit_date_field_query('FC')
      when 'exit_kc_date'
        values = program_exit_date_field_query('KC')
      when 'program_stream'
        values = program_stream_query
      when 'case_note_date'
        values = case_note_date_field_query
      when 'case_note_type'
        values = case_note_type_field_query
      when 'date_of_assessments'
        values = date_of_assessments_field_query
      end
      { id: sql_string, values: values }
    end

    private

    def date_of_assessments_field_query
      clients = @clients.joins(:assessments)
      case @operator
      when 'equal'
        clients = clients.where('date(assessments.created_at) = ?', @value.to_date)
      when 'not_equal'
        clients = clients.where("date(assessments.created_at) != ? OR assessments.created_at IS NULL", @value.to_date)
      when 'less'
        clients = clients.where('date(assessments.created_at) < ?', @value.to_date)
      when 'less_or_equal'
        clients = clients.where('date(assessments.created_at) <= ?', @value.to_date)
      when 'greater'
        clients = clients.where('date(assessments.created_at) > ?', @value.to_date)
      when 'greater_or_equal'
        clients = clients.where('date(assessments.created_at) >= ?', @value.to_date)
      when 'between'
        clients = clients.where('date(assessments.created_at) BETWEEN ? AND ? ', @value[0].to_date, @value[1].to_date)
      when 'is_empty'
        clients = clients.where(assessments: { created_at: nil })
      when 'is_not_empty'
        clients = clients.where.not(assessments: { created_at: nil })
      end
      clients.ids
    end

    def case_note_type_field_query
      clients = @clients.joins(:case_notes)
      case @operator
      when 'equal'
        clients = clients.where(case_notes: { interaction_type: @value })
      when 'not_equal'
        clients = clients.where.not(case_notes: { interaction_type: @value })
      when 'is_empty'
        clients = clients.where(case_notes: { interaction_type: '' })
      when 'is_not_empty'
        clients = clients.where.not(case_notes: { interaction_type: '' })
      end
      clients.ids
    end

    def case_note_date_field_query
      clients = @clients.joins(:case_notes)
      case @operator
      when 'equal'
        clients = clients.where(case_notes: { meeting_date: @value })
      when 'not_equal'
        clients = clients.where("case_notes.meeting_date != ? OR case_notes.meeting_date IS NULL", @value)
      when 'less'
        clients = clients.where('case_notes.meeting_date < ?', @value)
      when 'less_or_equal'
        clients = clients.where('case_notes.meeting_date <= ?', @value)
      when 'greater'
        clients = clients.where('case_notes.meeting_date > ?', @value)
      when 'greater_or_equal'
        clients = clients.where('case_notes.meeting_date >= ?', @value)
      when 'between'
        clients = clients.where(case_notes: { meeting_date: @value[0]..@value[1] })
      when 'is_empty'
        clients = clients.where(case_notes: { meeting_date: nil })
      when 'is_not_empty'
        clients = clients.where.not(case_notes: { meeting_date: nil })
      end
      clients.ids
    end

    def program_stream_query
      clients = @clients.joins(:client_enrollments).where(client_enrollments: { status: 'Active' })
      case @operator
      when 'equal'
        clients.where('client_enrollments.program_stream_id = ?', @value ).ids
      when 'not_equal'
        clients.where.not('client_enrollments.program_stream_id = ?', @value ).ids
      when 'is_empty'
        @clients.where.not(id: clients.ids).ids
      when 'is_not_empty'
        @clients.where(id: clients.ids).ids
      end
    end

    def placement_date_field_query
      clients = @clients.joins(:cases)

      case @operator
      when 'equal'
        clients = clients.where(cases: { start_date: @value })
      when 'not_equal'
        clients = clients.where("cases.start_date != ? OR cases.start_date IS NULL", @value)
      when 'less'
        clients = clients.where('cases.start_date < ?', @value)
      when 'less_or_equal'
        clients = clients.where('cases.start_date <= ?', @value)
      when 'greater'
        clients = clients.where('cases.start_date > ?', @value)
      when 'greater_or_equal'
        clients = clients.where('cases.start_date >= ?', @value)
      when 'between'
        clients = clients.where(cases: { start_date: @value[0]..@value[1] })
      when 'is_empty'
        ids = @clients.where.not(id: clients.ids).ids
      when 'is_not_empty'
        ids = @clients.where(id: clients.ids).ids
      end

      if @operator != 'is_empty'
        sub_query = 'SELECT MAX(cases.created_at) FROM cases WHERE cases.client_id = clients.id'
        ids = clients.where("cases.created_at = (#{sub_query})").ids
      end
      ids
    end

    def form_title_field_query
      clients = @clients.joins(:custom_fields)
      case @operator
      when 'equal'
        clients = clients.where('custom_fields.id = ?', @value)
      when 'not_equal'
        clients = clients.where.not('custom_fields.id = ?', @value)
      when 'is_empty'
        clients = @clients.where.not(id: clients.ids)
      when 'is_not_empty'
        clients = @clients.where(id: clients.ids)
      end
      clients.uniq.ids
    end

    def case_type_field_query
      clients = @clients.joins(:cases).where(cases: { exited: false })

      case @operator
      when 'equal'
        case_ids = clients.where(cases: { case_type: @value }).map { |c| c.cases.current.id if c.cases.current.case_type == @value }.uniq
        @clients.joins(:cases).where(cases: { id: case_ids }).ids
      when 'not_equal'
        case_ids = clients.where.not(cases: { case_type: @value }).map { |c| c.cases.current.id if c.cases.current.case_type != @value }.uniq
        @clients.joins(:cases).where(cases: { id: case_ids }).ids
      when 'is_empty'
        @clients.where.not(id: clients.ids).ids
      when 'is_not_empty'
        @clients.where(id: clients.ids).ids
      end
    end

    def agency_name_field_query
      clients = @clients.joins(:agencies)
      case @operator
      when 'equal'
        clients.where('agencies.id = ?', @value ).ids
      when 'not_equal'
        clients.where.not('agencies.id = ?', @value ).ids
      when 'is_empty'
        @clients.where.not(id: clients.ids).ids
      when 'is_not_empty'
        @clients.where(id: clients.ids).ids
      end
    end

    def user_id_field_query
      clients = @clients.joins(:users)
      case @operator
      when 'equal'
        clients.where('users.id = ?', @value ).ids
      when 'not_equal'
        clients.where.not('users.id = ?', @value ).ids
      when 'is_empty'
        @clients.where.not(id: clients.ids).ids
      when 'is_not_empty'
        @clients.where(id: clients.ids).ids
      end
    end


    def family_id_field_query
      @values = validate_family_id(@value)
      families = Family.where.not("children = '{}' OR children is null")

      case @operator
      when 'equal'
        client_ids = families.find_by(id: @values).try(:children)
      when 'not_equal'
        client_ids = families.where.not(id: @values).pluck(:children)
      when 'less'
        client_ids = families.where('id < ?', @values).pluck(:children)
      when 'less_or_equal'
        client_ids = families.where('id <= ?', @values).pluck(:children)
      when 'greater'
        client_ids = families.where('id > ?', @values).pluck(:children)
      when 'greater_or_equal'
        client_ids = families.where('id >= ?', @values).pluck(:children)
      when 'between'
        client_ids = families.where(id: @values[0]..@values[1]).pluck(:children)
      when 'is_empty'
        client_ids = families.pluck(:children).flatten.uniq
        client_ids = @clients.where.not(id: client_ids).pluck(:id).uniq
      when 'is_not_empty'
        client_ids = families.pluck(:children).flatten.uniq
        client_ids = @clients.where(id: client_ids).pluck(:id).uniq
      end
      clients = client_ids.present? ? @clients.where(id: client_ids.flatten.uniq).ids : []
    end

    def family_name_field_query
      @values = validate_family_id(@value)
      families = Family.where.not("children = '{}' OR children is null").uniq

      case @operator
      when 'equal'
        client_ids = families.find_by('lower(name) = ?', @values.downcase).try(:children)
      when 'not_equal'
        client_ids = families.where.not('lower(name) = ?', @values.downcase).pluck(:children)
      when 'contains'
        client_ids = families.where('name ILIKE ?', "%#{@values}%").pluck(:children)
      when 'not_contains'
        client_ids = families.where.not('name ILIKE ?', "%#{@values}%").pluck(:children)
      when 'is_empty'
        client_ids = families.pluck(:children).flatten.uniq
        client_ids = @clients.where.not(id: client_ids).pluck(:id).uniq
      when 'is_not_empty'
        client_ids = families.pluck(:children).flatten.uniq
        client_ids = @clients.where(id: client_ids).pluck(:id).uniq
      end

      clients = client_ids.present? ? @clients.where(id: client_ids.flatten.uniq).ids : []
    end

    # def family_id_field_query
    #   @values = validate_family_id(@value)
    #   sub_query = 'SELECT MAX(cases.created_at) FROM cases WHERE cases.client_id = clients.id'
    #   clients = @clients.joins(:families).joins(:cases).where("cases.created_at = (#{sub_query})")

    #   case @operator
    #   when 'equal'
    #     clients = clients.where('families.id = ? ', @values)
    #   when 'not_equal'
    #     clients = clients.where.not('families.id = ? ', @values)
    #   when 'less'
    #     clients = clients.where('families.id < ?', @values)
    #   when 'less_or_equal'
    #     clients = clients.where('families.id <= ?', @values)
    #   when 'greater'
    #     clients = clients.where('families.id > ?', @values)
    #   when 'greater_or_equal'
    #     clients = clients.where('families.id >= ?', @values)
    #   when 'between'
    #     clients = clients.where('families.id BETWEEN ? and ?', @values[0], @values[1])
    #   when 'is_empty'
    #     clients = @clients.where.not(id: clients.ids)
    #   when 'is_not_empty'
    #     clients = @clients.where(id: clients.ids)
    #   end
    #   clients.ids.uniq
    # end

    # def family_name_field_query
    #   sub_query = 'SELECT MAX(cases.created_at) FROM cases WHERE cases.client_id = clients.id'
    #   clients = @clients.joins(:families).joins(:cases).where("cases.created_at = (#{sub_query})")

    #   case @operator
    #   when 'equal'
    #     clients  = clients.where('lower(families.name) = ?', @value.downcase)
    #   when 'not_equal'
    #     clients  = clients.where.not('families.name = ?', @value)
    #   when 'contains'
    #     clients  = clients.where('families.name ILIKE ?', "%#{@value}%")
    #   when 'not_contains'
    #     clients  = clients.where.not('families.name ILIKE ?', "%#{@value}%")
    #   when 'is_empty'
    #     clients = @clients.where.not(id: clients.ids)
    #   when 'is_not_empty'
    #     clients = @clients.where(id: clients.ids)
    #   end
    #   clients.uniq.ids
    # end

    def age_field_query
      date_value_format = convert_age_to_date(@value)
      case @operator
      when 'equal'
        clients = @clients.where(date_of_birth: date_value_format.last_year.tomorrow..date_value_format)
      when 'not_equal'
        clients = @clients.where.not(date_of_birth: date_value_format.last_year.tomorrow..date_value_format)
      when 'less'
        clients = @clients.where('date_of_birth > ?', date_value_format)
      when 'less_or_equal'
        clients = @clients.where('date_of_birth >= ?', date_value_format.last_year)
      when 'greater'
        clients = @clients.where('date_of_birth < ?', date_value_format.last_year)
      when 'greater_or_equal'
        clients = @clients.where('date_of_birth <= ?', date_value_format)
      when 'between'
        clients = @clients.where(date_of_birth: date_value_format[0]..date_value_format[1])
      when 'is_empty'
        clients = @clients.where('date_of_birth IS NULL')
      when 'is_not_empty'
        clients = @clients.where.not('date_of_birth IS NULL')
      end
      clients.ids
    end

    def convert_age_to_date(value)
      overdue_year = 999.years.ago.to_date
      if value.is_a?(Array)
        min_age = (value[0].to_i * 12).months.ago.to_date
        max_age = ((value[1].to_i + 1) * 12).months.ago.to_date.tomorrow
        min_age = min_age > overdue_year ? min_age : overdue_year
        max_age = max_age > overdue_year ? max_age : overdue_year
        [max_age, min_age]
      else
        age = (value.to_i * 12).months.ago.to_date
        age > overdue_year ? age : overdue_year
      end
    end

    def validate_family_id(ids)
      if ids.is_a?(Array)
        first_value = ids.first.to_i > 1000000 ? "1000000" : ids.first
        last_value  = ids.last.to_i > 1000000 ? "1000000" : ids.last
        [first_value, last_value]
      else
        ids.to_i > 1000000 ? "1000000" : ids
      end
    end

    def program_placement_date_field_query(case_type)
      clients = @clients.joins(:cases)

      case @operator
      when 'equal'
        clients = clients.where(cases: { case_type: case_type, start_date: @value })
      when 'not_equal'
        clients = clients.where("cases.case_type = ? AND cases.start_date != ? OR cases.start_date IS NULL", case_type, @value)
      when 'less'
        clients = clients.where('cases.case_type = ? AND cases.start_date < ?', case_type, @value)
      when 'less_or_equal'
        clients = clients.where('cases.case_type = ? AND cases.start_date <= ?', case_type, @value)
      when 'greater'
        clients = clients.where('cases.case_type = ? AND cases.start_date > ?', case_type, @value)
      when 'greater_or_equal'
        clients = clients.where('cases.case_type = ? AND cases.start_date >= ?', case_type, @value)
      when 'between'
        clients = clients.where(cases: { case_type: case_type, start_date: @value[0]..@value[1] })
      when 'is_empty'
        ids = @clients.where.not(id: clients.ids).ids
      when 'is_not_empty'
        ids = @clients.where(id: clients.ids).ids
      end

      if @operator != 'is_empty'
        ids = clients.ids
      end
      ids
    end

    def program_exit_date_field_query(case_type)
      clients = @clients.joins(:cases)

      case @operator
      when 'equal'
        clients = clients.where(cases: { case_type: case_type, exit_date: @value, exited: true })
      when 'not_equal'
        clients = clients.where("cases.case_type = ? AND cases.exit_date != ? AND cases.exited = ?", case_type, @value, true)
      when 'less'
        clients = clients.where('cases.case_type = ? AND cases.exit_date < ? AND cases.exited = ?', case_type, @value, true)
      when 'less_or_equal'
        clients = clients.where('cases.case_type = ? AND cases.exit_date <= ? AND cases.exited = ?', case_type, @value, true)
      when 'greater'
        clients = clients.where('cases.case_type = ? AND cases.exit_date > ? AND cases.exited = ?', case_type, @value, true)
      when 'greater_or_equal'
        clients = clients.where('cases.case_type = ? AND cases.exit_date >= ? AND cases.exited = ?', case_type, @value, true)
      when 'between'
        clients = clients.where(cases: { case_type: case_type, exit_date: @value[0]..@value[1], exited: true })
      when 'is_empty'
        clients = clients.includes(:cases).where(cases: { case_type: case_type }).where('cases.exited = ? OR cases.id IS NULL', false)
      when 'is_not_empty'
        clients = clients.includes(:cases).where(cases: { case_type: case_type }).where.not('cases.exited = ? OR cases.id IS NULL', false)
      end
      clients.ids.uniq
    end
  end
end
