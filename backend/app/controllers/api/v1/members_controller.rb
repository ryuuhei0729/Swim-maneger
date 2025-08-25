class Api::V1::MembersController < Api::V1::BaseController
  def index
    users = User.all.sort_by { |user| [user.generation, user.name] }
    
    # 世代別にグループ化
    grouped_by_generation = users.group_by(&:generation)
    
    # ユーザータイプの表示順序を定義
    type_order = { "player" => 0, "manager" => 1, "coach" => 2, "director" => 3 }
    grouped_by_type = users.group_by(&:user_type)
                          .sort_by { |type, _| type_order[type] || 4 }
                          .to_h

    render_success({
      total_count: users.count,
      users: users.map { |user| format_user(user) },
      grouped_by_generation: grouped_by_generation.transform_values { |users| 
        users.map { |user| format_user(user) } 
      },
      grouped_by_type: grouped_by_type.transform_values { |users| 
        users.map { |user| format_user(user) } 
      }
    })
  end

  private

  def format_user(user)
    {
      id: user.id,
      name: user.name,
      generation: user.generation,
      user_type: user.user_type,
      user_type_label: user.user_type.humanize,
      gender: user.gender,
      gender_label: user.gender.humanize,
      age: calculate_age(user.birthday),
      profile_image_url: user.profile_image_url&.present? ? url_for(user.profile_image_url) : nil
    }
  end

  def calculate_age(birthday)
    return nil unless birthday
    
    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end
end 