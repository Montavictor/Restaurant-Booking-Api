class Api::V1::Versions::CoursesController < ApplicationController
  before_action :set_course, only: [:index, :revert]
  
  # GET /api/v1/versions/courses/:course_id/versions
  def index
    versions = @course.versions.order(created_at: :desc).map do |v|
      format_version_summmary(v)
    end
    render json: versions
  end

  # POST /api/v1/versions/courses/:course_id/versions/:id/revert
  def revert
    version = @course.versions.find(params[:id])
    if version.reify
      version.reify.save!
      render json: { message: "Course reverted to version #{params[:id]}" }, status: :ok
    else
      render json: { error: "Cannot revert to this version" }, status: :unprocessable_entity
    end
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end
end
