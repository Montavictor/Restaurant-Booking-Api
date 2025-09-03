class Api::V1::Versions::CoursesController < ApplicationController
  # Callbacks
  before_action :set_course, only: [:index, :show, :revert, :compare]
  before_action :set_version, only: [:show, :revert]

  # Rescue
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from StandardError, with: :handle_standard_error
  
  # GET /api/v1/courses/:course_id/versions
  def index
    if @course.versions.empty?
      render json: {
        message: "No versions available for this course"
      }
      return
    end

    versions = @course.versions.order(created_at: :desc).map do |v|
      format_version_summary(v)  
    end
    render json: {
      course: {
        id: @course.id,
        name: @course.name,
        current_version: @course.versions.count
      },
      versions: versions,
      meta: {
        total_versions: versions.count
      }
    }
  end

  # GET /api/v1/courses/:course_id/versions/:id/
  def show
    render json: {
      version: format_version_detail(@version),
      course: {
        id: @course.id,
        name: @course.name
      }
    }
  end

  # POST /api/v1/courses/:course_id/versions/:id/revert
  def revert
    @version = @course.versions.find(params[:id])

    if @version.event == "create"
      return render json: { error: "Cannot revert to the creation version" }, status: :unprocessable_entity
    end

    reverted_item =  @version.reify
    if reverted_item.nil?
      return render json: { error: "Cannot revert to this version" }, status: :unprocessable_entity
    end

    if reverted_item.save
      render json: {
        message: "Course reverted to version #{params[:id]}",
        course: {
          id: @course.id,
          name: reverted_item.name,
        }
      }, status: :ok
    else
      render json: { error: "Failed to revert course" }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/courses/:course_id/versions/compare/:version_1/:version_2
  def compare
    version_1 = @course.versions.find(params[:version_1])
    version_2 = @course.versions.find(params[:version_2])

    comparison = compare_versions(version_1, version_2)

    render json: {
      comparison: comparison,
      versions: {
        earlier: format_version_summary(version_1),
        later: format_version_summary(version_2)
      }
    }
  end

  private

  # Formatting return values of version summaries
  def format_version_summary(version)
    {
      id: version.id,
      event: version.event,
      event_description: event_description(version.event),
      whodunnit: version.whodunnit || "System",
      has_changes: version.object_changes.present?,
      created_at: version.created_at,
      formatted_date: version.created_at.strftime('%B %d, %Y at %I:%M %p'),
      changes_count: parse_object_changes(version)&.keys&.count || 0,
      changes_summary: format_changes_summary(version)
    }
  end

  def format_changes_summary(version)
    return {} unless version.object_changes.present?
    
    changes = parse_object_changes(version)
    return {} if changes.empty?

    summary = {}
    changes.each do |attribute, values|
      next unless values.is_a?(Array) && values.length == 2
      old_value, new_value = values
      
      summary[attribute] = {
        attribute_name: attribute.to_s.humanize,
        change_type: determine_change_type(old_value, new_value),
        old_value: format_value(old_value),
        new_value: format_value(new_value)
      }
    end
    
    summary
  end

  def format_changes(version)
    return {} unless version.object_changes.present?

    changes = parse_object_changes(version)
    formatted_changes = {}

    changes.each do |attribute, values|
      next if values.nil? || !values.is_a?(Array) || values.length != 2

      old_value, new_value = values

      formatted_changes[attribute] = {
        attribute_name: attribute.to_s.humanize,
        old_value: format_value(old_value),
        new_value: format_value(new_value),
        old_value_raw: old_value,
        new_value_raw: new_value,
        change_type: determine_change_type(old_value, new_value)
      }
    end
    formatted_changes
  end

  def format_value(value)
    case value
    when nil
      "(empty)"
    when ""
      "(blank)"
    when TrueClass
      "Yes"
    when FalseClass
      "No"
    when Time, DateTime, ActiveSupport::TimeWithZone
      value.strftime('%B %d, %Y at %I:%M %p')
    else
      value.to_s.truncate(100)
    end
  end

  def determine_change_type(old_value, new_value)
    if old_value.nil? && !new_value.nil?
      'added'
    elsif !old_value.nil? && new_value.nil?
      'removed'
    elsif old_value != new_value
      'modified'
    else
      'unchanged'
    end
  end

  def event_description(event)
    case event
    when 'create'
      'Created'
    when 'update'
      'Updated'
    when 'destroy'
      'Deleted'
    else
      event.humanize
    end
  end

  def format_version_detail(version)
    {
      id: version.id,
      event: version.event,
      event_description: event_description(version.event),
      created_at: version.created_at,
      formatted_date: version.created_at.strftime('%B %d, %Y at %I:%M %p'),
      user: version.whodunnit || 'System',
      changes: format_changes(version),
      item_type: version.item_type,
      item_id: version.item_id
    }
  end

  def parse_object_changes(version)
    return {} unless version.object_changes.present?
    YAML.load(version.object_changes) rescue {}
  end

  def compare_versions(version_1, version_2)
    changes_1 = parse_object_changes(version_1)
    changes_2 = parse_object_changes(version_2)

    all_attributes = (changes_1.keys + changes_2.keys).uniq

    comparison = {}
    all_attributes.each do |attr|
      v1_change = changes_1[attr]
      v2_change = changes_2[attr]
      
      comparison[attr] = {
        attribute_name: attr.to_s.humanize,
        version_1: {
          old_value: format_value(v1_change&.first),
          new_value: format_value(v1_change&.last)
        },
        version_2: {
          old_value: format_value(v2_change&.first),
          new_value: format_value(v2_change&.last)
        }
      }
    end
    comparison
  end

  # before_action
  def set_course
    @course = Course.find(params[:course_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Course not found" }, status: :not_found
  end

  def set_version
    @version = @course.versions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Version not found" }, status: :not_found
  end

  # rescue

  def record_not_found
    render json: { error: "Record not found" }, status: :not_found
  end

  def handle_standard_error(e)
    render json: { error: "An error occurred: #{e.message}" }, status: :unprocessable_entity
  end
end