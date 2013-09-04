require './lib/kan'

kan = Kan.new

#第3艦隊が暇なら補給して遠征5開始
kan.start_mission_if_possible(5,3)

#第2艦隊が暇なら補給して遠征9開始
kan.start_mission_if_possible(9,2)
