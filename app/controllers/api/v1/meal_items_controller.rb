class Api::V1::MealItemsController < ApplicationController
  before_action :set_course
  before_action :set_meal_item, only: [:show, :update, :destroy]

# GET /api/v1/courses/:course_id/meal_items
  def index
    meal_items = @course.meal_items
    render json: meal_items
  end

  # POST /api/v1/courses/:course_id/meal_items
  def create
    meal_item = @course.meal_items.new(meal_item_params)
    if meal_item.save
      render json: meal_item, status: :created
    else
      render json: { errors: meal_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/courses/:course_id/meal_items/:id
  def show
    render json: meal_item
  end

  # PATCH /api/v1/courses/:course_id/meal_items/:id
  def update
    if @meal_item.update(meal_item_params)
      render json: @meal_item
    else
      render json: { errors: @meal_item.errors.full_messages }, status: :unprocessable_entity 
    end
  end

  # DELETE /api/v1/courses/:course_id/meal_items/:id
  def destroy
    @meal_item.destroy
    head :no_content
  end

  private

  def set_meal_item
    meal_item = @course.meal_items.find(params[:id])
  end

  def meal_item_params
    params.require(:meal_item).permit(:name, :description)
  end

  def set_course
    @course = Course.find(params[:course_id])
  end
end
