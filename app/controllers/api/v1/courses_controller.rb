class Api::V1::CoursesController < ApplicationController
  before_action :set_course, only: [:show, :update, :destroy]

  # GET /api/v1/courses
  def index
    courses = Course.all
    render json: courses
  end

  # POST /api/v1/courses
  def create
    course = Course.new(course_params)
    
    if course.save
      render json: course, status: :created
    else
      render json: { errors: course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/courses/:id
  def show
    render json: @course
  end

  # PATCH /api/v1/courses/:id
  def update
    if @course.update(course_params)
      render json: @course
    else
      render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/courses/:id
  def destroy
    @course.destroy
    head :no_content
  end

  private

  def course_params
    params.require(:course).permit(:name, :position)
  end

  def set_course
    @course = Course.find(params[:id])
  end
end
