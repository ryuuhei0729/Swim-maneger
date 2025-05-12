class RaceFeedback < ApplicationRecord
  belongs_to :race_goal
  belongs_to :user

  validates :note, presence: true

  validate :user_must_be_coach

  private

  def user_must_be_coach
    unless user&.user_type == 'coach'
      errors.add(:user, 'must be a coach')
    end
  end
end 