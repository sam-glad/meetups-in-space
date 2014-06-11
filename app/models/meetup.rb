class Meetup < ActiveRecord::Base
  has_many :user_meetups
  has_many :users, through: :user_meetups
  validates :name, presence: true
  validates :location, presence: true
end
