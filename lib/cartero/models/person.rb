# Documentation for Person
class Person
  include MongoMapper::Document

  key :email, String, :unique => true
  key :campaigns, Array
  key :responded, Array
  key :credentials, Array

  timestamps!
  many :hits
end
