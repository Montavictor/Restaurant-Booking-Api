class CourseSerializer 
  include JSONAPI::Serializer
  attributes :id, :name, :position

  belongs_to :reservation_info
end