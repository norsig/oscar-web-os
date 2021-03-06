class AssessmentsController < AdminController
  load_and_authorize_resource

  before_action :find_client, :check_current_organization
  before_action :find_assessment, only: [:edit, :update, :show]
  before_action :restrict_invalid_assessment, only: [:new, :create]
  before_action :restrict_update_assessment, only: [:edit, :update]
  before_action -> { assessments_permission('readable') }, only: :show
  before_action -> { assessments_permission('editable') }, except: [:index, :show]

  def index
  end

  def new
    @assessment = @client.assessments.new
    @assessment.populate_notes
  end

  def create
    @assessment = @client.assessments.new(assessment_params)
    if @assessment.save
      redirect_to client_assessment_path(@client, @assessment), notice: t('.successfully_created')
    else
      render :new
    end
  end

  def show
    unless current_user.admin? || current_user.strategic_overviewer?
      redirect_to root_path, alert: t('unauthorized.default') unless current_user.permission.assessments_readable
    end
  end

  def edit
    unless current_user.admin? || current_user.strategic_overviewer?
      redirect_to root_path, alert: t('unauthorized.default') unless current_user.permission.assessments_editable
    end
  end

  def update
    params[:assessment][:assessment_domains_attributes].each do |assessment_domain|
      add_more_attachments(assessment_domain.second[:attachments], assessment_domain.second[:id])
    end
    if @assessment.update_attributes(assessment_params)
      @assessment.update(updated_at: DateTime.now)
      @assessment.assessment_domains.update_all(assessment_id: @assessment.id)
      redirect_to client_assessment_path(@client, @assessment), notice: t('.successfully_updated')
    else
      render :edit
    end
  end

  def destroy
    if params[:file_index].present?
      remove_attachment_at_index(params[:file_index].to_i)
      message ||= t('.successfully_deleted')
      respond_to do |f|
        f.json { render json: { message: message }, status: '200' }
      end
    end
  end

  private

  def find_client
    @client = Client.accessible_by(current_ability).friendly.find(params[:client_id])
  end

  def find_assessment
    @assessment = @client.assessments.find(params[:id])
  end

  def assessment_params
    # params.require(:assessment).permit(assessment_domains_attributes: [:id, :domain_id, :score, :reason, :goal])

    default_params = params.require(:assessment).permit(assessment_domains_attributes: [:id, :domain_id, :score, :reason, :goal])
    default_params = params.require(:assessment).permit(assessment_domains_attributes: [:id, :domain_id, :score, :reason, :goal, attachments: []]) if action_name == 'create'
    default_params
  end

  def restrict_invalid_assessment
    redirect_to client_assessments_path(@client) unless @client.can_create_assessment?
  end

  def restrict_update_assessment
    redirect_to client_assessments_path(@client) unless @assessment.latest_record?
  end

  def remove_attachment_at_index(index)
    assessment_domain = AssessmentDomain.find(params[:assessment_domain])
    remain_attachment = assessment_domain.attachments
    deleted_attachment = remain_attachment.delete_at(index)
    deleted_attachment.try(:remove_images!)
    remain_attachment.empty? ? assessment_domain.remove_attachments! : (assessment_domain.attachments = remain_attachment )
    message = t('.fail_delete_attachment') unless assessment_domain.save
  end

  def add_more_attachments(new_file, assessment_domain_id)
    if new_file.present?
      assessment_domain = AssessmentDomain.find(assessment_domain_id)
      files = assessment_domain.attachments
      files += new_file
      assessment_domain.attachments = files
      assessment_domain.save
    end
  end

  def assessments_permission(permission)
    unless current_user.admin? || current_user.strategic_overviewer?
      if permission == 'readable'
        redirect_to root_path, alert: t('unauthorized.default') unless current_user.permission.assessments_readable
      else
        redirect_to root_path, alert: t('unauthorized.default') unless current_user.permission.assessments_editable
      end
    end
  end

  def check_current_organization
    redirect_to dashboards_path, alert: t('unauthorized.default') if current_organization.mho?
  end
end
