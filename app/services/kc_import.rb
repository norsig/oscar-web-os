class KcImport
  def initialize
    Organization.switch_to 'cif'
    @clients = Client.joins(:cases).where(cases: { case_type: 'KC' }).uniq
    @program_stream = ProgramStream.find_by(name: 'Kinship Care')
    @tracking = @program_stream.trackings.first
  end


  def kc_import
    @clients.each do |client|
      client.cases.kinships.order(:created_at).each do |kinship|
        client_enrollment = client.client_enrollments.new(program_stream: @program_stream, enrollment_date: kinship.start_date)
        client_enrollment.save(validate: false)
        if (kinship.support_amount.present? && kinship.support_amount > 0) || kinship.support_note.present?
          client_enrollment_tracking = client_enrollment.client_enrollment_trackings.new(tracking: @tracking)
          client_enrollment_tracking.properties['Date of Support Start'] = kinship.start_date.to_s
          client_enrollment_tracking.properties['Total Support Amount'] = kinship.support_amount.to_f.to_s
          client_enrollment_tracking.properties['Support Note'] = kinship.support_note
          client_enrollment_tracking.save(validate: false)
        end

        if kinship.exited?
          leave_program = LeaveProgram.new(program_stream: @program_stream, exit_date: kinship.exit_date, client_enrollment: client_enrollment)
          exit_status = case kinship.status
          when 'Exited - Dead'
            'Client died'
          when 'Exited - Age Out'
            'Client over 18'
          when 'Exited Independent'
            'Client financially independent'
          when 'Exited Adopted'
            'Client adopted by foster family'
          else
            'Other'
          end
          leave_program.properties['Reason for Ending KC Placement'] = exit_status
          leave_program.properties['Notes on Program Exit'] = kinship.exit_note
          leave_program.save(validate: false)
        end
      end
    end
  end
end
