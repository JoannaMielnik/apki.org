class Course::Exercise
  include Mongoid::Document
  include Mongoid::Timestamps

  field :data, type: Hash

  belongs_to :course_lesson, :class_name => 'Course::Lesson'
end
