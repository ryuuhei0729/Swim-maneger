class CreateBestTimeTable < ActiveRecord::Migration[7.1]
  def change
    create_table :best_time_tables do |t|
      t.references :user, null: false, foreign_key: true
      
      # 自由形
      t.string :'50m_fr', default: '-'
      t.string :'50m_fr_note'
      t.string :'100m_fr', default: '-'
      t.string :'100m_fr_note'
      t.string :'200m_fr', default: '-'
      t.string :'200m_fr_note'
      t.string :'400m_fr', default: '-'
      t.string :'400m_fr_note'
      t.string :'800m_fr', default: '-'
      t.string :'800m_fr_note'
      
      # 平泳ぎ
      t.string :'50m_br', default: '-'
      t.string :'50m_br_note'
      t.string :'100m_br', default: '-'
      t.string :'100m_br_note'
      t.string :'200m_br', default: '-'
      t.string :'200m_br_note'
      
      # 背泳ぎ
      t.string :'50m_ba', default: '-'
      t.string :'50m_ba_note'
      t.string :'100m_ba', default: '-'
      t.string :'100m_ba_note'
      t.string :'200m_ba', default: '-'
      t.string :'200m_ba_note'
      
      # バタフライ
      t.string :'50m_fly', default: '-'
      t.string :'50m_fly_note'
      t.string :'100m_fly', default: '-'
      t.string :'100m_fly_note'
      t.string :'200m_fly', default: '-'
      t.string :'200m_fly_note'
      
      # 個人メドレー
      t.string :'100m_im', default: '-'
      t.string :'100m_im_note'
      t.string :'200m_im', default: '-'
      t.string :'200m_im_note'
      t.string :'400m_im', default: '-'
      t.string :'400m_im_note'

      t.timestamps
    end
  end
end