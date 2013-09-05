require './lib/kan'

kan = Kan.new

#第3艦隊が暇なら補給して遠征3開始
kan.start_mission_if_possible(3,3)

#第2艦隊が暇なら補給して遠征5開始
kan.start_mission_if_possible(5,2)
