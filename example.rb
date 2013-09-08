require './lib/kan'

kan = Kan.new

#第3艦隊が暇なら補給して遠征3開始
kan.start_mission_if_possible(3,3)

#第2艦隊が暇なら補給して遠征9開始
kan.start_mission_if_possible(9,2)

#可能なら損傷している船を入渠させる。
kan.nyukyo_any_ships_if_possible
