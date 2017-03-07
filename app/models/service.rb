class Service < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :health_endpoint, uniqueness: true
  validates :project, presence: true

  attr_accessor :is_user_entry_point

  belongs_to :project

  has_and_belongs_to_many :dependencies,
                            class_name: 'Service',
                            join_table: :dependencies,
                            foreign_key: :service_id,
                            association_foreign_key: :dependency_id,
                            uniq: true

  has_and_belongs_to_many :external_resources


  def status
    case current_status_code
    when 200..299
      :up
    when 300..499
      :config_error
    else
      :down
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
