# -*- coding: utf-8 -*-
require 'yaml'

class KanUtil
  attr_reader :main_deck_pools,:main_ship_ids

  def initialize(kan=nil)
    @kan = kan
    deck_config = YAML.load_file(File.expand_path('../../deck_config.yml', __FILE__))
    if deck_config["main_deck_pools"]
      @main_deck_pools = deck_config["main_deck_pools"]
      @main_ship_ids = @main_deck_pools.flatten
    end
  end

  #戦場に出れる艦隊を作る
  def build_all_green_deck(deck_id=1)
    raise "need Kan's instance" unless @kan
    raise "main_deck_pools not defined" unless @main_deck_pools

    deck = @kan.find_deck(deck_id)
    pairs = []

    #交替する艦船を探す
    deck.ship_ids.each do |ship_id|
      ship = @kan.find_ship(ship_id)
      unless @kan.ready_to_battle?(ship_id)
        alternatives = @main_deck_pools.find{|pool| pool.include?(ship_id) }
        return false unless alternatives
        alt_id = alternatives.find{|ship_id| !deck.ship_ids.include?(ship_id) && !pairs.any?{|pair| pair[1] == ship_id}  && @kan.ready_to_battle?(ship_id) }
        return false unless alt_id
        pairs << [ship_id,alt_id]
      end
    end

    #交替する
    pairs.each do |pair|
      index = deck.ship_ids.index(pair[0])
      @kan.change(pair[1],index,deck_id)
    end
    true
  end
end
