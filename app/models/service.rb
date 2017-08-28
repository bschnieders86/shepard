class Service < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  validates :name, presence: true, uniqueness: true
  validates :health_endpoint, length: {maximum: 512}
  validates :project, presence: true

  # validates :is_user_entry_point, length: {minimum: 1 }

  belongs_to :project

  has_and_belongs_to_many :dependencies,
                            class_name: 'Service',
                            join_table: :dependencies,
                            foreign_key: :service_id,
                            association_foreign_key: :dependency_id,
                            uniq: true

  has_and_belongs_to_many :external_resources

  attr_accessor :repository_url

  def internal_dependencies
    dependencies.select{|d| d.project == project}
  end

  def external_dependencies
    [direct_external_dependencies, implicit_dependencies].flatten
  end

  def direct_external_dependencies
    dependencies.select{|d| d.project != project}
  end

  def implicit_dependencies
    result = []
    external_resources.each do |resource|
      implicit_dependencies = resource.services.select{|s| s.project != project}
      result << implicit_dependencies
    end

    return result.flatten.uniq
  end

  def dependency_of
    services = []
    Dependency.where(dependency_id: id).find_each do |dependency|
      services << dependency.service
    end

    return services
  end

  def status
    if health_endpoint.present?
      case current_status_code
      when 200..299
        :up
      when 300..499
        :config_error
      else
        :down
      end
    else
      :no_status
    end
  end

  private

  def current_status_code
    Rails.cache.fetch("#{name}.status", expires_in: 5.seconds) do
      begin
        response = RestClient.get health_endpoint
        return response.code
      rescue
        return 500
      end
    end
  end


end
