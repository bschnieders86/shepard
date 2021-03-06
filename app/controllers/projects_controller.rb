# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_projects
  before_action :set_project, only: %i[show health incidents]
  before_action :load_incidents, only: %i[health incidents]

  # GET /projects
  # GET /projects.json
  def index
    network = NetworkBuilders::ProjectsNetworkBuilder.new(@projects).build
    gon.networkData = network.to_hash
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    network = NetworkBuilders::ProjectNetworkBuilder.new(@project).build
    gon.networkData = network.to_hash
  end

  def health
    network = NetworkBuilders::HealthNetworkBuilder.new(@project).build
    gon.networkData = network.to_hash
    gon.project = @project.slug
    gon.incidents = {alerts: @alerts, warnings: @warnings}

    respond_to do |format|
      format.html { render :health }
      format.json { render json: network.to_hash }
    end
  end

  def incidents
    response_body = {
      alerts: @alerts,
      warnings: @warnings
    }

    respond_to do |format|
      format.html { render :index }
      format.json { render json: response_body.to_json }
    end
  end

  private

  def load_incidents
    @alerts = @project.services.where(status: :down)
    @warnings = []
    @project.services.each do |service|
      service.dependencies.each do |dependency|
        @warnings << service if dependency.down?
      end
    end

    @warnings = @warnings.uniq.reject { |service| @alerts.map(&:name).include?(service.name) }
  end

  def set_project
    @project = Project.find_by(slug: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def project_params
    params.fetch(:project, {})
  end
end
