json.array!(@course_quizzes) do |course_quiz|
  json.extract! course_quiz, :id, :data, :parent_id
  json.url course_quiz_url(course_quiz, format: :json)
end
