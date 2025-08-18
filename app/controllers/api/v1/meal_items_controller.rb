class Api::V1::MealItemsController < ApplicationController
  before_action :set_api_v1_meal_item, only: %i[ show update destroy ]

  # GET /api/v1/meal_items
  def index
    @course = Api::V1::Course.find_by(id: params[:id])
    @api_v1_meal_items = @course.meal_items

    render json: @api_v1_meal_items
  end

  # GET /api/v1/meal_items/1
  def show
    render json: @api_v1_meal_item
  end

  # POST /api/v1/meal_items
  def create
    @api_v1_meal_item = Api::V1::MealItem.new(api_v1_meal_item_params)

    if @api_v1_meal_item.save
      render json: @api_v1_meal_item, status: :created, location: @api_v1_meal_item
    else
      render json: @api_v1_meal_item.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/meal_items/1
  def update
    if @api_v1_meal_item.update(api_v1_meal_item_params)
      render json: @api_v1_meal_item
    else
      render json: @api_v1_meal_item.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/meal_items/1
  def destroy
    @api_v1_meal_item.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_api_v1_meal_item
      @api_v1_meal_item = Api::V1::MealItem.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def api_v1_meal_item_params
      params.require(:api_v1_meal_item).permit(:name, :description, :course_id)
    end
end
