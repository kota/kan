# -*- coding: utf-8 -*-

class Dock
  attr_accessor :id, :state, :ship_id, :complete_time

  def initialize(json=nil)
    if json
      @id = json["api_id"].to_i
      @state = json["api_state"].to_i
      @ship_id = json["api_ship_id"].to_i
      @compete_time = json["api_complete_time"]
    end
  end

  def state_label
    case @state
    when 0
      "利用可能"
    when 1
      "使用中"
    when -1 
      "未解放"
    end
  end

  def to_s
    time = Time.at(@compete_time.to_s[0..-4].to_i).strftime("%H:%M:%S")
    s = "状態:#{state_label}"
    s += ",船ID:#{ship_id} #{time}まで" if @ship_id > 0
    s
  end

end

class Deck
  attr_accessor :id, :ship_ids, :mission_id, :mission_finishes_at

  def initialize(json=nil)
    if json
      @id = json["api_id"]
      @ship_ids = json["api_ship"].map(&:to_i)
      @mission_state = json["api_mission"][0]
      @mission_id = json["api_mission"][1]
      @mission_finishes_at = json["api_mission"][2]
    end
  end

  def in_mission?
    @mission_state == 1
  end

  def mission_finished?
    @mission_state == 2
  end

  def to_s
    time = Time.at(@mission_finishes_at.to_s[0..-4].to_i).strftime("%H:%M:%S")
    "艦隊#{@id} #{in_mission? ? "遠征中:#{@mission_id} #{time}まで" : ''}"
  end

end

class Ship
  attr_accessor :id, :name, :hp, :max_hp, :fuel, :max_fuel, :bullet, :max_bullet,
                :dock_items, :dock_time, :level, :condition, :exp

  def initialize(json=nil)
    @id = json["api_id"].to_i
    @name = json["api_name"]
    @hp = json["api_nowhp"].to_i
    @max_hp = json["api_maxhp"].to_i
    @fuel = json["api_fuel"].to_i
    @max_fuel = json["api_fuel_max"].to_i
    @bullet = json["api_bull"].to_i
    @max_bullet = json["api_bull_max"].to_i
    @dock_items = json["api_ndock_item"].map(&:to_i)
    @dock_time = json["api_ndock_time"].to_i
    @level = json["api_lv"].to_i
    @condition = json["api_cond"].to_i
    @exp = json["api_exp"].to_i
  end

  def to_s
    "#{@name}, id:#{@id}, lv:#{@level}, HP:#{@hp}/#{@max_hp}(#{damage_ratio}), 状態:#{@condition}, 燃料:#{@fuel}/#{@max_fuel}, 弾薬:#{@bullet}/#{@max_bullet}, 入渠:#{@dock_time}" 
  end

  def damaged?
    @hp < @max_hp
  end

  def enough_hp_for_battle?
    @hp.to_f / @max_hp.to_f >= 0.76
  end

  def need_supply?
    @fuel < @max_fuel || @bullet < @max_bullet
  end

  def good_condition?
    @condition >= 30
  end

  def all_green?
    enough_hp_for_battle? && good_condition? && !need_supply?
  end

  def damage_ratio
    (@hp / @max_hp.to_f).round(3)
  end

end

class Material
  attr_accessor :fuel, :bullet, :steel, :bauxite

  def initialize(json=nil)
    if json
      json.each do |mat|
        value = mat["api_value"].to_i
        case mat["api_id"].to_i
        when 1
          @fuel = value
        when 2
          @bullet = value
        when 3
          @steel = value
        when 4
          @bauxite = value
        end
      end
    end
  end
end

class Map
  attr_accessor :maparea_id, :mapinfo_no, :enemy, :item, :rashin_flag, :next

  def initialize(json=nil)
    if json
      @maparea_id = json["api_maparea_id"]
      @mapinfo_no = json["api_mapinfo_no"]
      @enemy = json["api_enemy"]
      @item = json["api_itemget"]
      @rashin_flag = json["api_rashin_flg"]
      @next = json["api_next"]
    end
  end

  def item?
    !!@item
  end

  def enemy?
    !!@enemy
  end

  def next?
    !!@next
  end
end

class Battle
  attr_accessor :midnight_flag

  def initialize(json=nil)
    if json
      @midnight_flag = json["api_midnight_flag"].to_i == 1
    end
  end

  def midnight?
    !!@midnight_flag
  end
end

class BattleResult
  attr_accessor :win_rank, :exps, :drop
  
  def initialize(json=nil)
    if json
      @win_rank = json["api_win_rank"]
      @exps = json["api_get_ship_exp"][1..-1].map(&:to_i)
      if json["api_get_ship"]
        @drop = json["api_get_ship"]["api_ship_name"]
      end
    end
  end

  def to_s
    s = "戦闘が終了しました。 判定:#{@win_rank}, 経験値:#{exps}"
    s += ", #{drop}を獲得しました" if !!@drop
    s
  end
end

