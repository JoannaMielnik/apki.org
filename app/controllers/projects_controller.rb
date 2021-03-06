class ProjectsController < ApplicationController
  before_action :is_logged_in, only: [:mine, :new, :edit, :update, :destroy, :vote]
  before_action :set_project, only: [:show, :edit, :update, :destroy, :repo, :vote]

  #skip_before_action :verify_authenticity_token, only: []

  # GET /projects
  def index
    @projects = Project.all
  end

  def contest_projects
    @projects = Project.where(contest: true).all
    render :index
  end

  def vote
    raise Exceptions::AccessDenied('Projekt nie jest konkursowy') unless @project.contest
    raise Exceptions::AccessDenied('Już oddałeś głos na ten projekt') if @project.votes.include? current_user.id.to_s
    raise Exceptions::AccessDenied('Już głosowałeś') if current_user.voted

    @project.votes << current_user.id.to_s
    @project.save!
    current_user.voted = true
    current_user.save!

    redirect_to project_path(@project), notice: 'Pomyślnie oddano głos'
  end

  # GET /projects/1
  def show
  end

  # GET /projects/mine
  def mine
    @projects = Project.where(user: current_user).all
  end

  # GET /projects/new
  def new
    @repositories = Octokit.repositories current_user.uid.to_i
    organizations = Octokit.organizations current_user.uid.to_i
    organizations.each do |org|
      @repositories.concat(Octokit.organization_repositories(org.id))
    end
    @project = Project.new
    @project.user = current_user
  end

  # GET /projects/1/edit
  def edit
    @repositories = Octokit.repositories current_user.uid.to_i
    organizations = Octokit.organizations current_user.uid.to_i
    organizations.each do |org|
      @repositories.concat(Octokit.organization_repositories(org.id))
    end
  end

  # POST /projects
  def create
    @repositories = Octokit.repositories current_user.uid.to_i
    organizations = Octokit.organizations current_user.uid.to_i
    organizations.each do |org|
      @repositories.concat(Octokit.organization_repositories(org.id))
    end
    @project = Project.new(project_params)
    @project.user = current_user
    if @project.save
      redirect_to @project, notice: 'Project został stworzony.'
    else
      render :new
    end
  end

  # PATCH/PUT /projects/1
  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project został zaktualizowany.'
    else
      render :edit
    end
  end

  # DELETE /projects/1
  def destroy
    @project.destroy
    redirect_to projects_url, notice: 'Project został usunięty.'
  end

  # POST /projects/repo/1.json
  def repo
    # readme, info, collaborators, commits, contributors
    repo = {}

    info = Octokit.repository @project.github

    repo['info'] = info.to_attrs
    begin
      repo['readme'] = Octokit.readme(@project.github, :accept => 'application/vnd.github.html').force_encoding('utf-8')
    rescue Octokit::NotFound
      repo['readme'] = ''
    end

    contributors = Octokit.contributors @project.github
    repo['contributors'] = contributors.map { |contributor| contributor.to_attrs }

    commits = Octokit.commits @project.github
    repo['commits'] = commits.map { |commit| commit.to_attrs }

    respond_to do |format|
      format.json { render :json => repo.to_json }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_project
    @project = Project.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    params.require(:project).permit(:title, :icon, :github, :contest)
  end
end
